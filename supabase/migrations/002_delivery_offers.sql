-- Delivery Offers System
-- Enables automated delivery assignment with accept/decline flow

-- =====================================================
-- 1. DELIVERY OFFERS TABLE
-- =====================================================
-- Tracks every offer made to every driver.
-- Enables: exclusive 5-min window, reconsider logic, no re-offering to decliners.
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
CREATE INDEX idx_delivery_offers_expires_at ON delivery_offers(expires_at) WHERE status = 'pending';

-- RLS
ALTER TABLE delivery_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drivers can view own offers" ON delivery_offers
  FOR SELECT USING (driver_id = auth.uid());

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_offers;

-- =====================================================
-- 2. UPDATE DELIVERIES TABLE
-- =====================================================
-- Add 'offered' to status constraint
ALTER TABLE deliveries DROP CONSTRAINT IF EXISTS deliveries_status_check;
ALTER TABLE deliveries ADD CONSTRAINT deliveries_status_check
  CHECK (status IN ('pending', 'offered', 'assigned', 'picked_up_from_farm', 'en_route', 'nearby_15_min', 'completed', 'failed'));

-- Add offer tracking columns
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS offered_driver_id UUID REFERENCES drivers(id);
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS offer_expires_at TIMESTAMPTZ;

-- =====================================================
-- 3. UPDATE RLS POLICIES
-- =====================================================
-- Drivers can now also see deliveries offered to them
DROP POLICY IF EXISTS "Drivers can view assigned deliveries" ON deliveries;
CREATE POLICY "Drivers can view assigned or offered deliveries" ON deliveries
  FOR SELECT USING (driver_id = auth.uid() OR offered_driver_id = auth.uid() OR driver_id IS NULL);
