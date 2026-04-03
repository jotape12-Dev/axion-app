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
    const { area, level, job_description, count } = await req.json();
    const geminiKey = Deno.env.get("GOOGLE_AI_API_KEY");

    if (!geminiKey) {
      throw new Error("GOOGLE_AI_API_KEY secret not configured");
    }

    const prompt = `Você é um entrevistador técnico sênior especialista em ${area}.
Gere exatamente ${count ?? 7} perguntas de entrevista técnica em português brasileiro.
Nível do candidato: ${level}.
${job_description ? `Vaga específica: ${job_description}` : ""}
As perguntas devem ser verbais — NUNCA peça para escrever código.
Cubra conceitos fundamentais, experiência prática, resolução de problemas e soft skills técnicas.
Comece com perguntas mais fáceis e aumente a dificuldade gradualmente.
Responda APENAS com um JSON array de strings, sem markdown, sem texto extra.
Exemplo: ["Pergunta 1?", "Pergunta 2?"]`;

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.7 },
        }),
      }
    );

    const data = await geminiResponse.json();
    console.log("Gemini response status:", geminiResponse.status);
    console.log("Gemini response data:", JSON.stringify(data));

    if (!geminiResponse.ok) {
      throw new Error(`Gemini API error ${geminiResponse.status}: ${data?.error?.message ?? JSON.stringify(data)}`);
    }

    if (!data.candidates || data.candidates.length === 0) {
      throw new Error(`Gemini returned no candidates. Full response: ${JSON.stringify(data)}`);
    }

    const rawText = data.candidates[0]?.content?.parts?.[0]?.text;
    if (!rawText) {
      throw new Error(`Gemini candidate has no text. Candidate: ${JSON.stringify(data.candidates[0])}`);
    }

    // Strip markdown code fences if present (e.g. ```json ... ```)
    const cleaned = rawText.replace(/```(?:json)?\s*/g, "").replace(/```/g, "").trim();
    const questions: string[] = JSON.parse(cleaned);

    return new Response(JSON.stringify({ questions }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("generate-questions error:", (error as Error).message);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
