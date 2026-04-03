// TTS is handled client-side via flutter_tts (device native TTS).
// This function is no longer used.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve((_req) => {
  return new Response(
    JSON.stringify({ message: "TTS is handled client-side." }),
    { headers: { "Content-Type": "application/json" } }
  );
});
