import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { audio, mime_type } = await req.json();
    const geminiKey = Deno.env.get("GOOGLE_AI_API_KEY")!;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                {
                  inline_data: {
                    mime_type: mime_type ?? "audio/m4a",
                    data: audio,
                  },
                },
                {
                  text: "Transcreva este áudio para texto em português brasileiro. Retorne apenas o texto transcrito, sem nenhum comentário adicional, formatação ou pontuação desnecessária.",
                },
              ],
            },
          ],
          generationConfig: { temperature: 0.0 },
        }),
      }
    );

    const data = await response.json();
    const transcript = data.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    return new Response(JSON.stringify({ transcript: transcript.trim() }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
