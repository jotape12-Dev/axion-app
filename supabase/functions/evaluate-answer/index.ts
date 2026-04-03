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
    const { question, answer, area, level } = await req.json();
    const geminiKey = Deno.env.get("GOOGLE_AI_API_KEY")!;

    const prompt = `Você é um avaliador de entrevistas técnicas em ${area}, nível ${level}.
Avalie a resposta do candidato à pergunta abaixo.

Pergunta: ${question}
Resposta do candidato: ${answer}

Retorne APENAS um JSON com:
- "score": número de 0 a 100
- "evaluation": uma das strings "Boa", "Parcial" ou "Insuficiente"
- "ideal_answer": resposta ideal resumida em 2-3 frases
- "feedback": feedback construtivo em 1-2 frases`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.3 },
        }),
      }
    );

    const data = await response.json();
    const rawText = data.candidates[0].content.parts[0].text;
    const cleaned = rawText.replace(/```(?:json)?\s*/g, "").replace(/```/g, "").trim();
    const result = JSON.parse(cleaned);

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
