# HelloZabiha Driver App - Technical Documentation

## Table of Contents
1. [App Overview](#app-overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Database Schema](#database-schema)
5. [Row Level Security Policies](#row-level-security-policies)
6. [Storage Buckets](#storage-buckets)
7. [Environment Setup](#environment-setup)

---

## App Overview

HelloZabiha Driver App is a Flutter-based mobile application for delivery drivers. It enables drivers to manage deliveries, track their location, communicate with customers, and view their earnings and performance analytics.

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **State Management**: Provider
- **Maps**: OpenStreetMap via flutter_map (no API key required)
- **Local Storage**: SharedPreferences

---

## Features

### 1. Authentication
- Email/password login and registration
- Supabase Auth integration
- Auto-login on app restart
- Secure session management

### 2. Home Dashboard
- Driver availability toggle
- Today's delivery count and earnings
- Active delivery status card
- Assigned deliveries queue
- Recent deliveries list
- Real-time data sync

### 3. Delivery Management
- View all deliveries (Pending, Active, Completed, Failed)
- Delivery detail view with:
  - Customer information
  - Pickup and delivery addresses
  - Order items list
  - Special instructions
  - Delivery timeline
- Status workflow:
  - `pending` → `assigned` → `picked_up_from_farm` → `en_route` → `nearby_15_min` → `completed`
- Failed delivery handling with reason capture

### 4. Delivery Completion Flow
- Photo capture for pickup confirmation
- Photo capture for delivery proof
- Digital signature capture
- Recipient name recording
- Automatic timestamp recording

### 5. Live Tracking & Maps
- Real-time location tracking
- OpenStreetMap integration
- Route visualization with polylines
- Turn-by-turn navigation (external app launch)
- ETA calculation and updates

### 6. In-App Messaging
- Real-time chat with customers
- Quick reply templates:
  - "On my way!"
  - "I've arrived"
  - "Running a few minutes late"
  - "Can you please come outside?"
- ETA update messages
- Status update notifications
- Unread message indicators

### 7. Notifications
- New delivery assignment alerts
- Real-time delivery status updates
- Push notification support
- Sound and vibration alerts
- In-app notification center

### 8. Driver Profile
- Personal information management
- Profile photo upload
- Vehicle information:
  - Type (car, SUV, van, truck, motorcycle, bicycle)
  - Model and year
  - License plate
- Capacity settings:
  - Cubic feet capacity
  - Max weight (lbs)
  - Max deliveries per run
  - Refrigeration capability
  - Cooler availability

### 9. Earnings & Analytics
- Daily/weekly/monthly earnings breakdown
- Delivery count statistics
- Performance metrics:
  - On-time delivery rate
  - Customer rating
  - Acceptance rate
- Visual charts and graphs
- Earnings history

### 10. Support System
- Help center with FAQs
- Contact support form
- Support ticket creation
- Ticket status tracking

### 11. Settings
- Theme toggle (Light/Dark mode)
- Notification preferences
- Terms of Service
- Privacy Policy
- Logout functionality

### 12. Offline Support
- Cached deliveries for offline viewing
- Cached driver profile
- Last sync time indicator
- Automatic sync on reconnection
- Graceful error handling

### 13. Error Handling
- User-friendly error messages
- Network error recovery
- Realtime subscription error handling
- Automatic retry mechanisms

---

## Architecture

### Directory Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── analytics.dart
│   ├── app_notification.dart
│   ├── delivery.dart
│   ├── driver.dart
│   ├── earning.dart
│   ├── faq.dart
│   ├── message.dart
│   └── order_item.dart
├── providers/                # State management
│   ├── analytics_provider.dart
│   ├── auth_provider.dart
│   ├── connectivity_provider.dart
│   ├── deliveries_provider.dart
│   ├── delivery_detail_provider.dart
│   ├── earnings_provider.dart
│   ├── home_provider.dart
│   ├── messaging_provider.dart
│   ├── notifications_provider.dart
│   ├── onboarding_provider.dart
│   ├── profile_provider.dart
│   └── theme_provider.dart
├── screens/                  # UI screens
│   ├── analytics/
│   ├── auth/
│   ├── deliveries/
│   ├── earnings/
│   ├── history/
│   ├── home/
│   ├── legal/
│   ├── messaging/
│   ├── notifications/
│   ├── onboarding/
│   ├── profile/
│   ├── settings/
│   ├── support/
│   ├── main_tab_screen.dart
│   └── splash_screen.dart
├── services/                 # Business logic & API
│   ├── analytics_service.dart
│   ├── auth_service.dart
│   ├── cache_service.dart
│   ├── connectivity_service.dart
│   ├── delivery_service.dart
│   ├── driver_service.dart
│   ├── earnings_service.dart
│   ├── location_service.dart
│   ├── messaging_service.dart
│   ├── navigation_service.dart
│   ├── notification_service.dart
│   ├── order_service.dart
│   ├── routing_service.dart
│   ├── supabase_service.dart
│   └── support_service.dart
├── theme/                    # App theming
│   └── app_theme.dart
├── utils/                    # Utilities
│   └── error_handler.dart
└── widgets/                  # Reusable widgets
```

### State Management Pattern
The app uses the **Provider** pattern for state management:
- Each feature has a corresponding Provider class
- Providers extend `ChangeNotifier`
- UI components use `Consumer` or `context.watch/read` to access state
- Services are singleton instances accessed via `ServiceName.instance`

---

## Database Schema

### 1. Drivers Table
Stores driver profile and vehicle information.

```sql
CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT DEFAULT '',
  profile_photo_url TEXT,

  -- Vehicle Information
  vehicle_type TEXT CHECK (vehicle_type IN ('car', 'suv', 'van', 'truck', 'motorcycle', 'bicycle')),
  vehicle_model TEXT,
  license_plate TEXT,
  vehicle_year INTEGER,

  -- Capacity Information
  capacity_cubic_feet DECIMAL,
  max_weight_lbs DECIMAL,
  max_deliveries_per_run INTEGER DEFAULT 10,
  has_refrigeration BOOLEAN DEFAULT false,
  has_cooler BOOLEAN DEFAULT false,

  -- Availability & Status
  is_available BOOLEAN DEFAULT false,
  is_on_delivery BOOLEAN DEFAULT false,
  current_latitude DECIMAL,
  current_longitude DECIMAL,

  -- Performance
  rating DECIMAL CHECK (rating >= 0 AND rating <= 5),
  total_deliveries INTEGER DEFAULT 0,
  completed_today INTEGER DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 2. Deliveries Table
Stores delivery orders and their status.

```sql
CREATE TABLE IF NOT EXISTS deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL,
  driver_id UUID REFERENCES drivers(id),

  -- Customer Information
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,

  -- Addresses
  pickup_address TEXT,
  pickup_latitude DECIMAL,
  pickup_longitude DECIMAL,
  pickup_notes TEXT,
  delivery_address TEXT NOT NULL,
  delivery_latitude DECIMAL,
  delivery_longitude DECIMAL,
  delivery_notes TEXT,

  -- Order Details
  item_count INTEGER DEFAULT 1,
  total_amount DECIMAL NOT NULL,
  special_instructions TEXT,

  -- Requirements
  requires_signature BOOLEAN DEFAULT false,
  requires_photo_proof BOOLEAN DEFAULT true,
  requires_refrigeration BOOLEAN DEFAULT false,

  -- Status & Timing
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'assigned', 'picked_up_from_farm', 'en_route',
    'nearby_15_min', 'completed', 'failed'
  )),
  estimated_minutes INTEGER,
  scheduled_pickup_time TIMESTAMPTZ,
  estimated_delivery_time TIMESTAMPTZ,
  actual_pickup_time TIMESTAMPTZ,
  actual_delivery_time TIMESTAMPTZ,

  -- Proof of Delivery
  pickup_photo_url TEXT,
  delivery_photo_url TEXT,
  signature_url TEXT,
  recipient_name TEXT,
  failure_reason TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3. Order Items Table
Stores individual items within an order.

```sql
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL,
  product_name TEXT NOT NULL,
  product_description TEXT,
  category TEXT,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit TEXT DEFAULT 'each',
  unit_price DECIMAL NOT NULL,
  total_price DECIMAL NOT NULL,
  notes TEXT,
  requires_refrigeration BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 4. Delivery Messages Table
Stores in-app chat messages between drivers and customers.

```sql
CREATE TABLE IF NOT EXISTS delivery_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('driver', 'customer')),
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text' CHECK (type IN (
    'text', 'quick_reply', 'location_update', 'eta_update', 'status_update'
  )),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 5. Support Tickets Table
Stores driver support requests.

```sql
CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  delivery_id UUID REFERENCES deliveries(id),
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### Database Indexes
```sql
CREATE INDEX IF NOT EXISTS idx_deliveries_driver_id ON deliveries(driver_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries(status);
CREATE INDEX IF NOT EXISTS idx_deliveries_created_at ON deliveries(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_messages_delivery_id ON delivery_messages(delivery_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON delivery_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_support_tickets_driver_id ON support_tickets(driver_id);
```

---

## Row Level Security Policies

### Drivers Table Policies

```sql
-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Drivers can view their own profile
CREATE POLICY "Drivers can view own profile" ON drivers
  FOR SELECT USING (auth.uid() = id);

-- Drivers can update their own profile
CREATE POLICY "Drivers can update own profile" ON drivers
  FOR UPDATE USING (auth.uid() = id);

-- Drivers can insert their own profile
CREATE POLICY "Drivers can insert own profile" ON drivers
  FOR INSERT WITH CHECK (auth.uid() = id);
```

### Deliveries Table Policies

```sql
-- Enable RLS
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

-- Drivers can view deliveries assigned to them
CREATE POLICY "Drivers can view assigned deliveries" ON deliveries
  FOR SELECT USING (driver_id = auth.uid() OR driver_id IS NULL);

-- Drivers can update deliveries assigned to them
CREATE POLICY "Drivers can update assigned deliveries" ON deliveries
  FOR UPDATE USING (driver_id = auth.uid());

-- Drivers can insert their own deliveries (for dev/testing)
CREATE POLICY "Drivers can insert their own deliveries" ON deliveries
  FOR INSERT WITH CHECK (driver_id = auth.uid());
```

### Order Items Table Policies

```sql
-- Enable RLS
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Authenticated users can view order items
CREATE POLICY "Authenticated users can view order items" ON order_items
  FOR SELECT USING (auth.role() = 'authenticated');
```

### Delivery Messages Table Policies

```sql
-- Enable RLS
ALTER TABLE delivery_messages ENABLE ROW LEVEL SECURITY;

-- Participants can view messages for their deliveries
CREATE POLICY "Participants can view messages" ON delivery_messages
  FOR SELECT USING (
    sender_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM deliveries
      WHERE deliveries.id = delivery_messages.delivery_id
      AND deliveries.driver_id = auth.uid()
    )
  );

-- Participants can send messages
CREATE POLICY "Participants can send messages" ON delivery_messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Participants can mark messages as read
CREATE POLICY "Participants can update messages" ON delivery_messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM deliveries
      WHERE deliveries.id = delivery_messages.delivery_id
      AND deliveries.driver_id = auth.uid()
    )
  );
```

### Support Tickets Table Policies

```sql
-- Enable RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Drivers can view their own tickets
CREATE POLICY "Drivers can view own tickets" ON support_tickets
  FOR SELECT USING (driver_id = auth.uid());

-- Drivers can create tickets
CREATE POLICY "Drivers can create tickets" ON support_tickets
  FOR INSERT WITH CHECK (driver_id = auth.uid());
```

---

## Storage Buckets

### Bucket Configuration

Create these buckets in Supabase Dashboard > Storage:

1. **avatars** - For driver profile photos (public)
2. **delivery-photos** - For pickup/delivery proof photos (public)

### Storage Policies

```sql
-- Profile Photos: Drivers can upload to their folder
CREATE POLICY "Drivers can upload profile photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Profile Photos: Anyone can view
CREATE POLICY "Anyone can view profile photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Profile Photos: Drivers can update their own
CREATE POLICY "Drivers can update own profile photos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Profile Photos: Drivers can delete their own
CREATE POLICY "Drivers can delete own profile photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Delivery Photos: Authenticated users can upload
CREATE POLICY "Drivers can upload delivery photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'delivery-photos' AND auth.role() = 'authenticated');

-- Delivery Photos: Anyone can view
CREATE POLICY "Anyone can view delivery photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'delivery-photos');
```

---

## Database Functions & Triggers

### Auto-update Timestamp Function

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
CREATE TRIGGER update_drivers_updated_at
  BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_deliveries_updated_at
  BEFORE UPDATE ON deliveries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Auto-create Driver Profile on Signup

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO drivers (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

---

## Realtime Subscriptions

Enable realtime for these tables:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE deliveries;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_messages;
```

---

## Environment Setup

### Required Environment Variables

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  supabase_flutter: ^2.8.0
  geolocator: ^13.0.2
  geocoding: ^3.0.0
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  url_launcher: ^6.3.1
  intl: ^0.20.2
  uuid: ^4.5.1
  http: ^1.2.2
  image_picker: ^1.1.2
  signature: ^5.5.0
  path_provider: ^2.1.5
  flutter_local_notifications: ^18.0.1
  vibration: ^2.0.1
  audioplayers: ^6.1.0
  connectivity_plus: ^6.1.1
  shared_preferences: ^2.3.4
  flutter_dotenv: ^5.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  integration_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.8
```

### Running the App

```bash
# Install dependencies
flutter pub get

# Run on iOS
cd ios && pod install && cd ..
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

---

## Delivery Status Flow

```
┌─────────┐    ┌──────────┐    ┌───────────────────┐
│ pending │───▶│ assigned │───▶│ picked_up_from_farm│
└─────────┘    └──────────┘    └───────────────────┘
                                        │
                                        ▼
                               ┌─────────────┐
                               │   en_route  │
                               └─────────────┘
                                        │
                                        ▼
                               ┌───────────────┐
                               │ nearby_15_min │
                               └───────────────┘
                                        │
                          ┌─────────────┴─────────────┐
                          ▼                           ▼
                   ┌───────────┐               ┌────────┐
                   │ completed │               │ failed │
                   └───────────┘               └────────┘
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-02 | Initial release with core delivery features |

---

*This documentation was generated for the HelloZabiha Driver App project.*
