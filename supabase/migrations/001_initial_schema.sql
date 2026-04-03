-- ============================================================
-- Axion — Schema inicial
-- Execute este SQL no Supabase Dashboard → SQL Editor
-- ============================================================

-- ─── profiles ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id                  uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email               text NOT NULL,
  display_name        text,
  photo_url           text,
  preferred_area      text,
  seniority_level     text,
  onboarding_completed boolean NOT NULL DEFAULT false,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: usuário gerencia o próprio perfil"
  ON profiles FOR ALL
  USING  (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ─── interviews ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS interviews (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  area             text NOT NULL,
  level            text NOT NULL,
  job_description  text,
  status           text NOT NULL DEFAULT 'in_progress',
  overall_score    integer,
  technical_score  integer,
  clarity_score    integer,
  fluency_score    integer,
  ended_early      boolean NOT NULL DEFAULT false,
  created_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE interviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "interviews: usuário gerencia as próprias entrevistas"
  ON interviews FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── interview_questions ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS interview_questions (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_id            uuid NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  question_order          integer NOT NULL,
  question                text NOT NULL,
  user_answer_transcript  text,
  score                   integer,
  ideal_answer            text,
  evaluation              text,
  created_at              timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE interview_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "interview_questions: acesso via entrevista do usuário"
  ON interview_questions FOR ALL
  USING (
    auth.uid() = (SELECT user_id FROM interviews WHERE id = interview_id)
  )
  WITH CHECK (
    auth.uid() = (SELECT user_id FROM interviews WHERE id = interview_id)
  );

-- ─── action_plans ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS action_plans (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_id     uuid NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  critical_points  text[] NOT NULL DEFAULT '{}',
  review_points    text[] NOT NULL DEFAULT '{}',
  strengths        text[] NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE action_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "action_plans: acesso via entrevista do usuário"
  ON action_plans FOR ALL
  USING (
    auth.uid() = (SELECT user_id FROM interviews WHERE id = interview_id)
  )
  WITH CHECK (
    auth.uid() = (SELECT user_id FROM interviews WHERE id = interview_id)
  );
