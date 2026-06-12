-- Migration 030: Add aliases columns for diacritics-insensitive search and alternative names

ALTER TABLE public.cities ADD COLUMN aliases TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.cities ADD COLUMN country_aliases TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.pois ADD COLUMN aliases TEXT[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.cities.aliases IS 'Alternative names for the city (e.g. Pilsen, Pilsner for Plzeň)';
COMMENT ON COLUMN public.cities.country_aliases IS 'Alternative names for the country (e.g. Czechia for Czech Republic)';
COMMENT ON COLUMN public.pois.aliases IS 'Alternative names for the POI (e.g. Old Town Square for Staroměstské náměstí)';
