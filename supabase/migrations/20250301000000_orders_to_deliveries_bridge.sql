-- Bridge: Auto-create deliveries from orders
-- This trigger fires when a new order is placed in the orders table
-- and creates a corresponding delivery record so drivers can see it.

-- =====================================================
-- 1. ENABLE pg_net EXTENSION (for calling Edge Functions)
-- =====================================================
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- =====================================================
-- 2. FUNCTION: Create delivery from order
-- =====================================================
-- SECURITY DEFINER so it can read auth.users for customer info
CREATE OR REPLACE FUNCTION create_delivery_from_order()
RETURNS TRIGGER AS $$
DECLARE
  customer_name_val TEXT;
  customer_phone_val TEXT;
  new_delivery_id UUID;
  item_count_val INTEGER;
  service_key TEXT;
BEGIN
  -- Look up customer info from auth.users
  SELECT
    COALESCE(raw_user_meta_data->>'name', raw_user_meta_data->>'full_name', split_part(email, '@', 1)),
    COALESCE(raw_user_meta_data->>'phone', phone, '')
  INTO customer_name_val, customer_phone_val
  FROM auth.users
  WHERE id = NEW.user_id;

  -- Count order items (if any exist)
  SELECT COUNT(*) INTO item_count_val
  FROM order_items
  WHERE order_id::text = NEW.id::text;

  -- Default to 1 if no items found yet (items may be inserted after order)
  IF item_count_val = 0 THEN
    item_count_val := 1;
  END IF;

  -- Create delivery record
  INSERT INTO deliveries (
    order_id,
    customer_name,
    customer_phone,
    delivery_address,
    delivery_notes,
    total_amount,
    item_count,
    estimated_delivery_time,
    status
  ) VALUES (
    NEW.id,
    COALESCE(customer_name_val, 'Customer'),
    COALESCE(customer_phone_val, ''),
    COALESCE(NEW.delivery_address, 'Address pending'),
    NEW.delivery_note,
    COALESCE(NEW.total, 0),
    item_count_val,
    NEW.estimated_delivery,
    'pending'
  )
  RETURNING id INTO new_delivery_id;

  -- Call the offer-delivery Edge Function via pg_net
  -- This automatically finds an available driver and sends them the offer
  BEGIN
    SELECT decrypted_secret INTO service_key
    FROM vault.decrypted_secrets
    WHERE name = 'service_role_key'
    LIMIT 1;

    IF service_key IS NOT NULL THEN
      PERFORM net.http_post(
        url := 'https://xdatjvzwjevqqugynkyf.supabase.co/functions/v1/offer-delivery',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || service_key
        ),
        body := jsonb_build_object('delivery_id', new_delivery_id)
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Don't fail the order if the offer trigger fails
    -- The delivery is still created and can be offered manually
    RAISE WARNING 'Failed to trigger offer-delivery: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. TRIGGER: Fire on new orders
-- =====================================================
CREATE TRIGGER on_order_created
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION create_delivery_from_order();

-- =====================================================
-- 4. RPC: Respond to delivery offer (accept/decline)
--    Called from the driver app instead of Edge Functions
-- =====================================================
CREATE OR REPLACE FUNCTION respond_to_delivery_offer(
  p_offer_id UUID,
  p_action TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_offer RECORD;
  v_now TIMESTAMPTZ := now();
  v_result JSONB;
BEGIN
  IF p_action NOT IN ('accept', 'decline') THEN
    RAISE EXCEPTION 'action must be accept or decline';
  END IF;

  SELECT * INTO v_offer FROM delivery_offers WHERE id = p_offer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Offer not found';
  END IF;

  IF v_offer.status != 'pending' THEN
    RAISE EXCEPTION 'Offer is no longer pending';
  END IF;

  IF p_action = 'accept' THEN
    IF v_offer.expires_at < v_now THEN
      UPDATE delivery_offers SET status = 'expired', responded_at = v_now WHERE id = p_offer_id;
      RAISE EXCEPTION 'Offer has expired';
    END IF;

    UPDATE delivery_offers SET status = 'accepted', responded_at = v_now WHERE id = p_offer_id;

    UPDATE deliveries SET
      status = 'assigned',
      driver_id = v_offer.driver_id,
      offered_driver_id = NULL,
      offer_expires_at = NULL
    WHERE id = v_offer.delivery_id;

    UPDATE drivers SET is_on_delivery = true WHERE id = v_offer.driver_id;

    v_result := jsonb_build_object('success', true, 'action', 'accepted', 'delivery_id', v_offer.delivery_id);
  END IF;

  IF p_action = 'decline' THEN
    UPDATE delivery_offers SET status = 'declined', responded_at = v_now WHERE id = p_offer_id;

    UPDATE deliveries SET
      status = 'pending',
      offered_driver_id = NULL,
      offer_expires_at = NULL
    WHERE id = v_offer.delivery_id;

    v_result := jsonb_build_object('success', true, 'action', 'declined', 'delivery_id', v_offer.delivery_id);
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. BACKFILL: Create deliveries for existing orders
--    that don't have a delivery record yet
-- =====================================================
INSERT INTO deliveries (
  order_id,
  customer_name,
  customer_phone,
  delivery_address,
  delivery_notes,
  total_amount,
  item_count,
  estimated_delivery_time,
  status
)
SELECT
  o.id,
  COALESCE(u.raw_user_meta_data->>'name', u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1), 'Customer'),
  COALESCE(u.raw_user_meta_data->>'phone', u.phone, ''),
  COALESCE(o.delivery_address, 'Address pending'),
  o.delivery_note,
  COALESCE(o.total, 0),
  GREATEST(1, (SELECT COUNT(*) FROM order_items oi WHERE oi.order_id::text = o.id::text)),
  o.estimated_delivery,
  'pending'
FROM orders o
LEFT JOIN auth.users u ON u.id = o.user_id
WHERE NOT EXISTS (
  SELECT 1 FROM deliveries d WHERE d.order_id::text = o.id::text
)
AND o.status = 'pending';
