import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Lade Keys aus Secrets
    const admobAppId = Deno.env.get("ADMOB_APP_ID_ANDROID") || "";
    const admobBanner320x50 = Deno.env.get("ADMOB_BANNER_320x50_ANDROID") || "";
    const revenuecatKey = Deno.env.get("REVENUECAT_PUBLIC_SDK_KEY_ANDROID") || "";

    // Wichtig: Nur nicht-sensitive Infos zurückgeben
    // Service Role Keys NIEMALS an Client schicken!
    const config = {
      admob: {
        appId: admobAppId,
        banner320x50: admobBanner320x50,
      },
      revenuecat: {
        publicSdkKey: revenuecatKey,
      },
    };

    return new Response(JSON.stringify(config), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
