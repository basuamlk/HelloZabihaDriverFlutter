# Automated Delivery Assignment with Accept/Decline Flow — Design Document

> **Date**: 2026-02-06
> **Status**: Planned — awaiting implementation

## Context

The HelloZabiha Driver app needs automated delivery assignment. Currently deliveries are pre-assigned (status jumps straight to `assigned`). The new system:

- A **Supabase Edge Function** offers deliveries to one driver at a time
- The driver gets a **5-minute exclusive window** to accept or decline via a **full-screen overlay**
- During the countdown, **no other driver sees that order**
- On decline/timeout, the delivery is **offered to the next available driver**
- Drivers can **reconsider** and reclaim a previously declined delivery if it hasn't been taken
- The internal admin app (separate project) will handle manual assignment later — out of scope here

## Architecture Overview

```
New Order Created (pending, driver_id=NULL)
  → Edge Function: offer-delivery
    → Finds best available driver (is_available=true, is_on_delivery=false, highest rating)
    → Creates offer record in delivery_offers table (5-min expiry)
    → Updates delivery status to "offered", sets offered_driver_id
  → Driver app detects offer via Supabase realtime subscription on delivery_offers table
    → Full-screen overlay appears with delivery details + 5-min countdown
      → ACCEPT → Edge Function: respond-to-offer → delivery becomes "assigned"
      → DECLINE → Edge Function: respond-to-offer → offer next driver
      → TIMEOUT (5 min) → auto-decline, same as above
  → Declined deliveries shown in "Recently Declined" section on home screen
    → Driver can tap "Accept" if delivery is still available (status='pending')
    → If taken by another driver → show "This delivery has already been taken"
```

---

## Step 1: Database Migration

**New file**: `supabase/migrations/002_delivery_offers.sql`

### 1a. New `delivery_offers` table

Tracks every offer made to every driver. Enables reconsider logic and prevents re-offering to drivers who already declined.

```sql
CREATE TABLE IF NOT EXISTS delivery_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
  offered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_delivery_offers_driver_status ON delivery_offers(driver_id, status);
CREATE INDEX idx_delivery_offers_delivery_status ON delivery_offers(delivery_id, status);

-- RLS
ALTER TABLE delivery_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can view own offers" ON delivery_offers
  FOR SELECT USING (driver_id = auth.uid());

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_offers;
```

### 1b. Update `deliveries` table

```sql
-- Add 'offered' to status constraint
ALTER TABLE deliveries DROP CONSTRAINT IF EXISTS deliveries_status_check;
ALTER TABLE deliveries ADD CONSTRAINT deliveries_status_check
  CHECK (status IN ('pending', 'offered', 'assigned', 'picked_up_from_farm', 'en_route', 'nearby_15_min', 'completed', 'failed'));

-- Add offer tracking columns
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS offered_driver_id UUID REFERENCES drivers(id);
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS offer_expires_at TIMESTAMPTZ;
```

### 1c. Update RLS policies

```sql
-- Drivers can also see deliveries offered to them
DROP POLICY IF EXISTS "Drivers can view assigned deliveries" ON deliveries;
CREATE POLICY "Drivers can view assigned or offered deliveries" ON deliveries
  FOR SELECT USING (driver_id = auth.uid() OR offered_driver_id = auth.uid() OR driver_id IS NULL);
```

---

## Step 2: Supabase Edge Functions

**Directory**: `supabase/functions/`

All Edge Functions use the Supabase service role key for full database access.

### 2a. `offer-delivery` Edge Function

**Trigger**: Called when a new delivery is created (via DB trigger or webhook), or when an offer is declined/expired.

**Input**: `{ delivery_id: string }`

**Logic**:
1. Fetch the delivery — must be `pending` or `offered` with an expired offer
2. Get all driver IDs who already declined this delivery (from `delivery_offers` where `status IN ('declined', 'expired')`)
3. Query `drivers` table: `is_available=true`, `is_on_delivery=false`, NOT in declined list, ordered by `rating DESC`
4. If no drivers available → leave delivery as `pending` with no `offered_driver_id` (will be picked up when a driver becomes available or checked periodically)
5. If driver found → insert `delivery_offers` row with `expires_at = now() + interval '5 minutes'`
6. Update delivery: `status='offered'`, `offered_driver_id=driver_id`, `offer_expires_at=expires_at`
7. Return the created offer

### 2b. `respond-to-offer` Edge Function

**Input**: `{ offer_id: string, action: 'accept' | 'decline' }`

**Logic (accept)**:
1. Fetch offer — verify it exists, is `pending`, and `expires_at > now()`
2. Update offer: `status='accepted'`, `responded_at=now()`
3. Update delivery: `status='assigned'`, `driver_id=offer.driver_id`, clear `offered_driver_id` and `offer_expires_at`
4. Update driver: `is_on_delivery=true`
5. Return success

**Logic (decline)**:
1. Update offer: `status='declined'`, `responded_at=now()`
2. Update delivery: `status='pending'`, clear `offered_driver_id` and `offer_expires_at`
3. Call `offer-delivery` logic internally to find and offer to the next available driver
4. Return success

### 2c. `reclaim-delivery` Edge Function

**Input**: `{ delivery_id: string }`

Called when a driver who previously declined wants to accept the delivery.

**Logic**:
1. Verify the calling driver has a previous `declined` offer for this delivery (in `delivery_offers`)
2. Check delivery current status — must be `pending` (NOT `offered` to someone else, NOT `assigned`)
3. If available → create new offer with `status='accepted'`, update delivery to `status='assigned'`, `driver_id=caller`
4. If not available → return error `{ error: "This delivery has already been taken" }`

### 2d. `check-expired-offers` Edge Function

**Trigger**: Can be called periodically via pg_cron, or triggered by the driver app when an offer times out client-side.

**Logic**:
1. Find offers where `status='pending'` AND `expires_at < now()`
2. For each: update to `status='expired'`, `responded_at=now()`
3. For each associated delivery: call `offer-delivery` logic to offer to next driver

---

## Step 3: Flutter Model Changes

### 3a. Update `DeliveryStatus` enum

**File**: `lib/models/delivery.dart`

Add `offered` between `pending` and `assigned`:
- `value`: `'offered'`
- `displayName`: `'Offer Pending'`
- `color`: `Colors.amber`
- `icon`: `Icons.notifications_active`
- `buttonTitle`: `null` (no action button — handled by offer screen)
- `nextStatus`: `DeliveryStatus.assigned`
- `isPending`: `true`
- `isActive`: `false`
- `progressPercentage`: `0.05`
- `stepIndex`: `0`

Update `fromString` to handle `'offered'`.

Add fields to `Delivery` class:
- `String? offeredDriverId`
- `DateTime? offerExpiresAt`

Update `fromJson`, `toJson`, `copyWith` accordingly.

### 3b. New `DeliveryOffer` model

**New file**: `lib/models/delivery_offer.dart`

```dart
enum OfferStatus { pending, accepted, declined, expired }

class DeliveryOffer {
  final String id;
  final String deliveryId;
  final String driverId;
  final OfferStatus status;
  final DateTime offeredAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;

  // Constructor, fromJson, toJson, copyWith
}
```

---

## Step 4: Flutter Service — `OfferService`

**New file**: `lib/services/offer_service.dart`

Singleton pattern (same as all other services in the app).

**Methods**:
- `Future<Map<String, dynamic>> respondToOffer(String offerId, String action)` — calls `respond-to-offer` Edge Function via `Supabase.functions.invoke()`
- `Future<Map<String, dynamic>> reclaimDelivery(String deliveryId)` — calls `reclaim-delivery` Edge Function
- `Future<DeliveryOffer?> getActiveOffer()` — query `delivery_offers` where `driver_id=currentUser`, `status='pending'`, `expires_at > now()`
- `Future<List<DeliveryOffer>> getDeclinedOffers()` — query `delivery_offers` where `driver_id=currentUser`, `status='declined'`, `offered_at > now() - 1 hour`
- `Stream<List<Map<String, dynamic>>> subscribeToOffers()` — realtime stream on `delivery_offers` filtered by `driver_id=currentUser`

---

## Step 5: Flutter Provider — `DeliveryOfferProvider`

**New file**: `lib/providers/delivery_offer_provider.dart`

### State
- `DeliveryOffer? currentOffer` — the active offer being shown
- `Delivery? currentOfferDelivery` — delivery details for the current offer
- `List<DeclinedOfferInfo> declinedOffers` — recently declined (includes delivery + availability status)
- `int remainingSeconds` — countdown timer value (starts at 300 = 5 min)
- `bool isResponding` — loading state during accept/decline API calls
- `String? errorMessage`

### Initialization
- Subscribe to `delivery_offers` realtime stream for this driver
- Check for any existing active offer on app startup (in case app was closed during an offer)

### Key Methods
- `initialize()` — start realtime subscription, check for active offer
- `_onOfferReceived(DeliveryOffer offer)` — fetch delivery details, start countdown timer, notify listeners (UI shows overlay)
- `acceptOffer()` — call `OfferService.respondToOffer(id, 'accept')`, clear currentOffer, stop timer
- `declineOffer()` — call `OfferService.respondToOffer(id, 'decline')`, add to declinedOffers, clear currentOffer, stop timer
- `_onCountdownExpired()` — auto-decline (call declineOffer or directly mark as expired via Edge Function)
- `reclaimDelivery(String deliveryId)` — call `OfferService.reclaimDelivery(deliveryId)`, handle success/error
- `loadDeclinedOffers()` — fetch from OfferService, check each delivery's current status for availability
- `refreshSubscription()` — restart realtime subscription (called after login)

### Countdown Timer
- Uses `Timer.periodic(Duration(seconds: 1), ...)`
- Calculates `remainingSeconds` from `offer.expiresAt - DateTime.now()`
- When `remainingSeconds <= 0` → auto-decline

---

## Step 6: Flutter UI — Delivery Offer Screen

**New file**: `lib/screens/deliveries/delivery_offer_screen.dart`

Full-screen modal/route that appears when a new offer arrives.

### Layout
```
┌──────────────────────────────────┐
│         NEW DELIVERY OFFER       │
│                                  │
│      ┌─────────────────┐         │
│      │   ⏱️  4:32      │         │
│      │  (circular       │         │
│      │   countdown)     │         │
│      └─────────────────┘         │
│                                  │
│  📍 Pickup: HelloZabiha Farm     │
│  📍 Deliver: 123 Main St        │
│  👤 John Smith                   │
│  📦 3 items · $45.50             │
│  🧊 Requires refrigeration      │
│  📝 Special: Ring doorbell       │
│                                  │
│  ┌────────────────────────────┐  │
│  │      ✅ ACCEPT ORDER       │  │
│  └────────────────────────────┘  │
│                                  │
│        ❌ Decline                 │
│                                  │
└──────────────────────────────────┘
```

### Behavior
- `WillPopScope` (or `PopScope`) prevents back button dismissal
- Countdown shows minutes:seconds with circular progress indicator
- Accept button is large, green, prominent
- Decline is a subtle text button
- On accept → show brief success animation, pop screen, refresh home
- On decline → pop screen immediately
- On timer expire → show "Offer expired" briefly, auto-pop
- Plays notification sound + vibration when screen appears

---

## Step 7: Home Screen — "Recently Declined" Section

**File**: `lib/screens/home/home_screen.dart`

Add new section below "Assigned Deliveries":

```
Recently Declined (2)
┌───────────────────────────────────────┐
│ 📍 123 Main St · 3 items · $45.50    │
│ Declined 2 min ago                    │
│                          [Still Available] ← green badge
│                          [Accept]     │
└───────────────────────────────────────┘
┌───────────────────────────────────────┐
│ 📍 456 Oak Ave · 1 item · $22.00     │
│ Declined 8 min ago                    │
│                          [Taken] ← grey badge
└───────────────────────────────────────┘
```

- Each row shows delivery summary, time since declined, and availability
- "Still Available" (green) → delivery status is `pending`, show "Accept" button
- "Taken" (grey) → delivery is `assigned`/`offered` to another driver, no action
- Tapping "Accept" calls `DeliveryOfferProvider.reclaimDelivery(deliveryId)`
- On success → navigate to `DeliveryDetailScreen`
- On failure → show snackbar "This delivery has already been taken"
- Only show offers declined within the last 1 hour

---

## Step 8: Integration & Wiring

### 8a. Register provider in `main.dart`
```dart
ChangeNotifierProvider(create: (_) => DeliveryOfferProvider()..initialize()),
```

### 8b. Offer overlay trigger
In `MainTabScreen` (or `AuthWrapper`), listen to `DeliveryOfferProvider`:
```dart
// When currentOffer becomes non-null, push DeliveryOfferScreen
Consumer<DeliveryOfferProvider>(
  builder: (context, offerProvider, child) {
    if (offerProvider.currentOffer != null && !_offerScreenShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOfferScreen(context);
      });
    }
    return child!;
  },
  child: // existing MainTabScreen content
)
```

### 8c. Update `NotificationsProvider`
**File**: `lib/providers/notifications_provider.dart`
- In `_handleDeliveryUpdates`: detect `offered` status where `offered_driver_id` matches current user
- Trigger notification sound + vibration via `NotificationService`

### 8d. Update `HomeProvider`
**File**: `lib/providers/home_provider.dart`
- `_processDeliveries`: include `offered` status in pending count
- Add declined offers data loading (delegate to `DeliveryOfferProvider`)

### 8e. Update `DeliveryService`
**File**: `lib/services/delivery_service.dart`
- `getPendingDeliveries()`: add `'offered'` to the `inFilter` status list

---

## Files Summary

### New Files (9)
| File | Purpose |
|------|---------|
| `supabase/migrations/002_delivery_offers.sql` | DB migration for offers table + delivery updates |
| `supabase/functions/offer-delivery/index.ts` | Find driver, create offer |
| `supabase/functions/respond-to-offer/index.ts` | Accept or decline an offer |
| `supabase/functions/reclaim-delivery/index.ts` | Reclaim a previously declined delivery |
| `supabase/functions/check-expired-offers/index.ts` | Handle expired offers periodically |
| `lib/models/delivery_offer.dart` | DeliveryOffer model |
| `lib/services/offer_service.dart` | Edge Function API calls + realtime subscription |
| `lib/providers/delivery_offer_provider.dart` | Offer state, countdown, declined offers |
| `lib/screens/deliveries/delivery_offer_screen.dart` | Full-screen offer overlay UI |

### Modified Files (6)
| File | Changes |
|------|---------|
| `lib/models/delivery.dart` | Add `offered` status + `offeredDriverId`/`offerExpiresAt` fields |
| `lib/main.dart` | Register `DeliveryOfferProvider` |
| `lib/screens/home/home_screen.dart` | Add "Recently Declined" section |
| `lib/providers/home_provider.dart` | Include `offered` in delivery processing |
| `lib/providers/notifications_provider.dart` | Detect `offered` status for notifications |
| `lib/services/delivery_service.dart` | Include `offered` in pending filter |

---

## Verification / Testing Plan

1. **DB**: Run migration, verify `delivery_offers` table created and `deliveries.status` accepts `'offered'`
2. **Edge Function (offer-delivery)**: Insert a delivery with `status='pending'`, invoke function, verify offer created and delivery updated
3. **Accept flow**: Call `respond-to-offer` with `accept`, verify delivery → `assigned`, offer → `accepted`, driver → `is_on_delivery=true`
4. **Decline flow**: Call with `decline`, verify offer → `declined`, delivery → `pending`, next driver gets offered
5. **Timeout flow**: Let 5 min expire, verify `check-expired-offers` marks offer as `expired` and re-offers
6. **Full-screen overlay**: Open driver app, trigger an offer, verify overlay appears with countdown
7. **Reconsider flow**: Decline an offer, verify it appears in "Recently Declined", tap Accept, verify reclaim works
8. **Reconsider blocked**: Have another driver accept the delivery first, verify reclaim returns "already taken"
9. **Exclusive window**: With 2 test drivers, verify only 1 sees the offer at a time
