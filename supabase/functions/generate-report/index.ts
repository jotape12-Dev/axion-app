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
    const { interview_id, questions, area, level } = await req.json();
    const geminiKey = Deno.env.get("GOOGLE_AI_API_KEY")!;

    const questionsText = questions
      .map(
        (q: { question: string; answer: string; score?: number }, i: number) =>
          `Pergunta ${i + 1}: ${q.question}\nResposta: ${q.answer}\nScore individual: ${q.score ?? "N/A"}`
      )
      .join("\n\n");

    const interviewUuid = interview_id;
    const now = new Date().toISOString();
    const actionPlanId = crypto.randomUUID();

    const prompt = `Você é um avaliador sênior de entrevistas técnicas em ${area}, nível ${level}.
Com base nas perguntas e respostas abaixo, gere um relatório completo.

${questionsText}

Retorne APENAS um JSON com:
- "overall_score": número de 0 a 100 (média ponderada: técnico 50%, clareza 30%, fluência 20%)
- "technical_score": número de 0 a 100
- "clarity_score": número de 0 a 100
- "fluency_score": número de 0 a 100
- "action_plan": {
    "id": "${actionPlanId}",
    "interview_id": "${interviewUuid}",
    "critical_points": [lista de 2-4 strings com pontos críticos a melhorar],
    "review_points": [lista de 2-3 strings com pontos a revisar],
    "strengths": [lista de 2-3 strings com pontos fortes],
    "created_at": "${now}"
  }`;

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
