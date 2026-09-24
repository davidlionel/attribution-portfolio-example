-- 02_platform_view.sql
-- What the ad platform can show you, and where it stops.

-- Spend and clicks by channel. This much any dashboard gives you.
SELECT
  channel,
  SUM(spend)       AS spend,
  SUM(clicks)      AS clicks,
  SUM(impressions) AS impressions,
  ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS cost_per_click
FROM paid_media.ad_spend
GROUP BY 1
ORDER BY spend DESC;


-- Cost per lead. This is as far as the platform can take you, because a
-- "conversion" in an ad platform is a form fill. What happened afterwards
-- lives in the CRM and never travels back.
--
-- Spend and leads are aggregated separately before being joined. Joining the
-- raw tables on channel would fan each spend row out across every lead in
-- that channel and inflate spend by orders of magnitude.
WITH spend AS (
  SELECT channel, SUM(spend) AS spend
  FROM paid_media.ad_spend
  GROUP BY 1
),
lead_counts AS (
  SELECT channel, COUNT(*) AS leads
  FROM paid_media.leads
  GROUP BY 1
)
SELECT
  l.channel,
  COALESCE(s.spend, 0) AS spend,
  l.leads,
  ROUND(COALESCE(s.spend, 0) / NULLIF(l.leads, 0), 2) AS cost_per_lead
FROM lead_counts l
LEFT JOIN spend s USING (channel)
ORDER BY cost_per_lead;

-- Ranked this way, Display ($37) and Meta ($43) are the best buys in the
-- account and LinkedIn ($177) is the worst. That conclusion is wrong, and
-- nothing in the ad platform can tell you so.
