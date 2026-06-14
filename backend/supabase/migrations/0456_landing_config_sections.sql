-- Migration 0456: extend the landing CMS (landing_config) to cover the remaining
-- content sections that were previously i18n-only: Explore, Featured, How It
-- Works (+ 3 steps) and the closing CTA. Applies after 0455. Idempotent.
--
-- All columns are per-language JSONB and default to '{}', so LandingPage keeps
-- falling back to its i18n keys when a value is missing — non-breaking.

ALTER TABLE public.landing_config
  ADD COLUMN IF NOT EXISTS explore_title    JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS explore_desc     JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS featured_title   JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS featured_desc    JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_title        JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_desc         JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_step1_title  JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_step1_desc   JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_step2_title  JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_step2_desc   JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_step3_title  JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS how_step3_desc   JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS cta_title        JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS cta_desc         JSONB NOT NULL DEFAULT '{}'::jsonb;
