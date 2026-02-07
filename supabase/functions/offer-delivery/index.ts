import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SERVICE_ROLE_KEY")!
    );

    const { delivery_id } = await req.json();

    if (!delivery_id) {
      return new Response(
        JSON.stringify({ error: "delivery_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch delivery — must be pending or offered with expired offer
    const { data: delivery, error: deliveryError } = await supabase
      .from("deliveries")
      .select("*")
      .eq("id", delivery_id)
      .single();

    if (deliveryError || !delivery) {
      return new Response(
        JSON.stringify({ error: "Delivery not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Only offer if delivery is pending, or offered but the offer expired
    if (delivery.status === "offered") {
      if (delivery.offer_expires_at && new Date(delivery.offer_expires_at) > new Date()) {
        return new Response(
          JSON.stringify({ error: "Delivery already has an active offer" }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } else if (delivery.status !== "pending") {
      return new Response(
        JSON.stringify({ error: "Delivery is not available for offering" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Get driver IDs who already declined or had expired offers for this delivery
    const { data: previousOffers } = await supabase
      .from("delivery_offers")
      .select("driver_id")
      .eq("delivery_id", delivery_id)
      .in("status", ["declined", "expired"]);

    const excludedDriverIds = (previousOffers || []).map((o: { driver_id: string }) => o.driver_id);

    // 3. Find best available driver
    let query = supabase
      .from("drivers")
      .select("*")
      .eq("is_available", true)
      .eq("is_on_delivery", false)
      .order("rating", { ascending: false, nullsFirst: false })
      .limit(1);

    // Supabase JS doesn't support NOT IN directly, so we filter client-side if needed
    const { data: availableDrivers, error: driversError } = await query;

    if (driversError) {
      return new Response(
        JSON.stringify({ error: "Failed to query drivers" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Filter out excluded drivers
    const eligibleDrivers = (availableDrivers || []).filter(
      (d: { id: string }) => !excludedDriverIds.includes(d.id)
    );

    // If we filtered everyone out, get more and filter again
    let selectedDriver = eligibleDrivers[0];

    if (!selectedDriver && excludedDriverIds.length > 0) {
      const { data: moreDrivers } = await supabase
        .from("drivers")
        .select("*")
        .eq("is_available", true)
        .eq("is_on_delivery", false)
        .order("rating", { ascending: false, nullsFirst: false })
        .limit(20);

      const moreEligible = (moreDrivers || []).filter(
        (d: { id: string }) => !excludedDriverIds.includes(d.id)
      );
      selectedDriver = moreEligible[0];
    }

    // 4. No drivers available — leave as pending
    if (!selectedDriver) {
      await supabase
        .from("deliveries")
        .update({
          status: "pending",
          offered_driver_id: null,
          offer_expires_at: null,
        })
        .eq("id", delivery_id);

      return new Response(
        JSON.stringify({ message: "No available drivers", delivery_id }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Create offer with 5-minute expiry
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

    const { data: offer, error: offerError } = await supabase
      .from("delivery_offers")
      .insert({
        delivery_id,
        driver_id: selectedDriver.id,
        status: "pending",
        offered_at: new Date().toISOString(),
        expires_at: expiresAt,
      })
      .select()
      .single();

    if (offerError) {
      return new Response(
        JSON.stringify({ error: "Failed to create offer" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Update delivery status
    await supabase
      .from("deliveries")
      .update({
        status: "offered",
        offered_driver_id: selectedDriver.id,
        offer_expires_at: expiresAt,
      })
      .eq("id", delivery_id);

    return new Response(
      JSON.stringify({ offer, driver_id: selectedDriver.id }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
