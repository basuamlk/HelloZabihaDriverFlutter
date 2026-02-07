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

    const { offer_id, action } = await req.json();

    if (!offer_id || !action) {
      return new Response(
        JSON.stringify({ error: "offer_id and action are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!["accept", "decline"].includes(action)) {
      return new Response(
        JSON.stringify({ error: "action must be 'accept' or 'decline'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch the offer
    const { data: offer, error: offerError } = await supabase
      .from("delivery_offers")
      .select("*")
      .eq("id", offer_id)
      .single();

    if (offerError || !offer) {
      return new Response(
        JSON.stringify({ error: "Offer not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (offer.status !== "pending") {
      return new Response(
        JSON.stringify({ error: "Offer is no longer pending" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const now = new Date().toISOString();

    if (action === "accept") {
      // Check if offer has expired
      if (new Date(offer.expires_at) < new Date()) {
        // Mark as expired instead
        await supabase
          .from("delivery_offers")
          .update({ status: "expired", responded_at: now })
          .eq("id", offer_id);

        return new Response(
          JSON.stringify({ error: "Offer has expired" }),
          { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Accept: update offer
      await supabase
        .from("delivery_offers")
        .update({ status: "accepted", responded_at: now })
        .eq("id", offer_id);

      // Accept: update delivery to assigned
      await supabase
        .from("deliveries")
        .update({
          status: "assigned",
          driver_id: offer.driver_id,
          offered_driver_id: null,
          offer_expires_at: null,
        })
        .eq("id", offer.delivery_id);

      // Accept: mark driver as on delivery
      await supabase
        .from("drivers")
        .update({ is_on_delivery: true })
        .eq("id", offer.driver_id);

      return new Response(
        JSON.stringify({ success: true, action: "accepted", delivery_id: offer.delivery_id }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "decline") {
      // Decline: update offer
      await supabase
        .from("delivery_offers")
        .update({ status: "declined", responded_at: now })
        .eq("id", offer_id);

      // Decline: reset delivery to pending
      await supabase
        .from("deliveries")
        .update({
          status: "pending",
          offered_driver_id: null,
          offer_expires_at: null,
        })
        .eq("id", offer.delivery_id);

      // Offer to next driver by invoking offer-delivery
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")!;

      // Fire-and-forget: offer to next driver
      fetch(`${supabaseUrl}/functions/v1/offer-delivery`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${serviceRoleKey}`,
        },
        body: JSON.stringify({ delivery_id: offer.delivery_id }),
      }).catch(() => {
        // Non-critical: if re-offering fails, delivery stays pending
      });

      return new Response(
        JSON.stringify({ success: true, action: "declined", delivery_id: offer.delivery_id }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
