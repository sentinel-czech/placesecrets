-- 042: Add comment and is_hidden columns to poi_ratings
ALTER TABLE public.poi_ratings
  ADD COLUMN comment   TEXT CHECK (char_length(comment) <= 1000),
  ADD COLUMN is_hidden BOOLEAN NOT NULL DEFAULT FALSE;
