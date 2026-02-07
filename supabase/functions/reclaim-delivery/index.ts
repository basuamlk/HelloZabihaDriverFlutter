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

    // Get the calling driver's ID from the auth token
    const authHeader = req.headers.get("Authorization")!;
    const { data: { user }, error: authError } = await createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!
    ).auth.getUser(authHeader.replace("Bearer ", ""));

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { delivery_id } = await req.json();

    if (!delivery_id) {
      return new Response(
        JSON.stringify({ error: "delivery_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Verify calling driver previously declined this delivery
    const { data: previousOffer } = await supabase
      .from("delivery_offers")
      .select("*")
      .eq("delivery_id", delivery_id)
      .eq("driver_id", user.id)
      .eq("status", "declined")
      .limit(1)
      .single();

    if (!previousOffer) {
      return new Response(
        JSON.stringify({ error: "No previous declined offer found" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Check delivery status — must be pending (not offered to someone else or assigned)
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

    if (delivery.status !== "pending") {
      return new Response(
        JSON.stringify({ error: "This delivery has already been taken" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Reclaim: create accepted offer and assign delivery
    const now = new Date().toISOString();

    await supabase.from("delivery_offers").insert({
      delivery_id,
      driver_id: user.id,
      status: "accepted",
      offered_at: now,
      expires_at: now,
      responded_at: now,
    });

    await supabase
      .from("deliveries")
      .update({
        status: "assigned",
        driver_id: user.id,
        offered_driver_id: null,
        offer_expires_at: null,
      })
      .eq("id", delivery_id);

    await supabase
      .from("drivers")
      .update({ is_on_delivery: true })
      .eq("id", user.id);

    return new Response(
      JSON.stringify({ success: true, delivery_id }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
