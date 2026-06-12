-- Migration 031: Extract countries into separate table

-- Create countries table
CREATE TABLE public.countries (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  aliases TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Backfill from existing cities (one row per distinct country_code)
INSERT INTO public.countries (code, name, aliases)
SELECT DISTINCT ON (country_code)
  country_code, country, country_aliases
FROM public.cities
ORDER BY country_code, created_at ASC
ON CONFLICT (code) DO NOTHING;

-- FK constraint
ALTER TABLE public.cities
  ADD CONSTRAINT fk_cities_country
  FOREIGN KEY (country_code) REFERENCES public.countries(code);

-- Drop redundant columns from cities
ALTER TABLE public.cities DROP COLUMN country;
ALTER TABLE public.cities DROP COLUMN country_aliases;

-- RLS
ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "countries_read" ON public.countries FOR SELECT USING (true);

-- Updated_at trigger
CREATE TRIGGER countries_updated_at
  BEFORE UPDATE ON public.countries
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
