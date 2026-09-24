-- 01_setup.sql
-- Schema and type correction.

CREATE SCHEMA IF NOT EXISTS paid_media;

-- Load the three CSVs from /data into:
--   paid_media.ad_spend   (90 rows)
--   paid_media.leads      (8,134 rows)
--   paid_media.deals      (512 rows)


-- Two columns arrive as text because they contain blanks, and a blank is not
-- NULL. Casting '' fails, so NULLIF has to clear the empties before the cast
-- sees them.
--
-- deals.lead_id matters most: 34 deals have no lead at all. If those import as
-- empty strings rather than NULLs, the unattributed query in 04 silently
-- returns zero and you never notice the gap.

ALTER TABLE paid_media.deals
  ALTER COLUMN close_date TYPE date
    USING NULLIF(close_date, '')::date,
  ALTER COLUMN lead_id TYPE text
    USING NULLIF(lead_id, '');

UPDATE paid_media.deals SET lead_id = NULL WHERE lead_id = '';


-- is_closed and is_closed_won are written as true/false. Most importers infer
-- boolean. If yours brought them in as text, run this; if they are already
-- boolean, skip it.
--
-- ALTER TABLE paid_media.deals
--   ALTER COLUMN is_closed TYPE boolean USING is_closed::boolean,
--   ALTER COLUMN is_closed_won TYPE boolean USING is_closed_won::boolean;


-- Sanity checks before analysis.
SELECT COUNT(*) AS spend_rows FROM paid_media.ad_spend;   -- 90
SELECT COUNT(*) AS lead_rows  FROM paid_media.leads;      -- 8134
SELECT COUNT(*) AS deal_rows  FROM paid_media.deals;      -- 512
SELECT COUNT(*) AS unattributed FROM paid_media.deals
WHERE lead_id IS NULL;                                    -- 34
