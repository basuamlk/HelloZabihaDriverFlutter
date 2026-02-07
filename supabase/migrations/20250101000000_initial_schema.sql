-- HelloZabiha Driver App Database Schema
-- Run these migrations in your Supabase SQL editor

-- =====================================================
-- 1. DRIVERS TABLE
-- =====================================================
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

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Drivers can read/update their own profile
CREATE POLICY "Drivers can view own profile" ON drivers
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Drivers can update own profile" ON drivers
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Drivers can insert own profile" ON drivers
  FOR INSERT WITH CHECK (auth.uid() = id);

-- =====================================================
-- 2. DELIVERIES TABLE
-- =====================================================
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

-- Enable RLS
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

-- Drivers can view deliveries assigned to them
CREATE POLICY "Drivers can view assigned deliveries" ON deliveries
  FOR SELECT USING (driver_id = auth.uid() OR driver_id IS NULL);

-- Drivers can update deliveries assigned to them
CREATE POLICY "Drivers can update assigned deliveries" ON deliveries
  FOR UPDATE USING (driver_id = auth.uid());

-- =====================================================
-- 3. ORDER ITEMS TABLE
-- =====================================================
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

-- Enable RLS
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Anyone can read order items (they're tied to orders anyway)
CREATE POLICY "Authenticated users can view order items" ON order_items
  FOR SELECT USING (auth.role() = 'authenticated');

-- =====================================================
-- 4. DELIVERY MESSAGES TABLE (In-app messaging)
-- =====================================================
CREATE TABLE IF NOT EXISTS delivery_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('driver', 'customer')),
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'quick_reply', 'location_update', 'eta_update', 'status_update')),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

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

-- =====================================================
-- 5. SUPPORT TICKETS TABLE
-- =====================================================
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

-- Enable RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Drivers can view their own tickets
CREATE POLICY "Drivers can view own tickets" ON support_tickets
  FOR SELECT USING (driver_id = auth.uid());

-- Drivers can create tickets
CREATE POLICY "Drivers can create tickets" ON support_tickets
  FOR INSERT WITH CHECK (driver_id = auth.uid());

-- =====================================================
-- 6. INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_deliveries_driver_id ON deliveries(driver_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries(status);
CREATE INDEX IF NOT EXISTS idx_deliveries_created_at ON deliveries(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_messages_delivery_id ON delivery_messages(delivery_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON delivery_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_support_tickets_driver_id ON support_tickets(driver_id);

-- =====================================================
-- 7. STORAGE BUCKETS
-- =====================================================
-- Run these in the Supabase Dashboard > Storage

-- Create bucket for profile photos
-- INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', true);

-- Create bucket for delivery photos
-- INSERT INTO storage.buckets (id, name, public) VALUES ('delivery-photos', 'delivery-photos', true);

-- Storage policies (run in SQL editor):
-- CREATE POLICY "Drivers can upload profile photos"
-- ON storage.objects FOR INSERT
-- WITH CHECK (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Anyone can view profile photos"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'profile-photos');

-- CREATE POLICY "Drivers can upload delivery photos"
-- ON storage.objects FOR INSERT
-- WITH CHECK (bucket_id = 'delivery-photos' AND auth.role() = 'authenticated');

-- CREATE POLICY "Anyone can view delivery photos"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'delivery-photos');

-- =====================================================
-- 8. FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_drivers_updated_at
  BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_deliveries_updated_at
  BEFORE UPDATE ON deliveries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to create driver profile on signup
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

-- Trigger to create driver profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- 9. REALTIME SUBSCRIPTIONS
-- =====================================================
-- Enable realtime for deliveries table
ALTER PUBLICATION supabase_realtime ADD TABLE deliveries;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_messages;
