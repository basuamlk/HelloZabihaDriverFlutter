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

    const now = new Date().toISOString();

    // Find all pending offers that have expired
    const { data: expiredOffers, error } = await supabase
      .from("delivery_offers")
      .select("*")
      .eq("status", "pending")
      .lt("expires_at", now);

    if (error) {
      return new Response(
        JSON.stringify({ error: "Failed to query expired offers" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!expiredOffers || expiredOffers.length === 0) {
      return new Response(
        JSON.stringify({ message: "No expired offers", count: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const processedDeliveryIds: string[] = [];

    for (const offer of expiredOffers) {
      // Mark offer as expired
      await supabase
        .from("delivery_offers")
        .update({ status: "expired", responded_at: now })
        .eq("id", offer.id);

      // Reset delivery to pending (if not already re-offered)
      await supabase
        .from("deliveries")
        .update({
          status: "pending",
          offered_driver_id: null,
          offer_expires_at: null,
        })
        .eq("id", offer.delivery_id)
        .in("status", ["offered"]);

      processedDeliveryIds.push(offer.delivery_id);
    }

    // Re-offer each unique delivery to the next driver
    const uniqueDeliveryIds = [...new Set(processedDeliveryIds)];
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")!;

    for (const deliveryId of uniqueDeliveryIds) {
      fetch(`${supabaseUrl}/functions/v1/offer-delivery`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${serviceRoleKey}`,
        },
        body: JSON.stringify({ delivery_id: deliveryId }),
      }).catch(() => {
        // Non-critical: delivery stays pending if re-offer fails
      });
    }

    return new Response(
      JSON.stringify({
        message: "Expired offers processed",
        count: expiredOffers.length,
        reoffered: uniqueDeliveryIds.length,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
