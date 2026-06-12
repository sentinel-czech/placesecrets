-- 039: Backfill uploaded_by from POI contributor for existing audio guides
UPDATE poi_audio_guides ag
SET uploaded_by = p.contributor_id
FROM pois p
WHERE ag.poi_id = p.id
  AND ag.uploaded_by IS NULL
  AND p.contributor_id IS NOT NULL;
