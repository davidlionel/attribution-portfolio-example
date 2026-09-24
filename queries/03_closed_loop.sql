-- 03_closed_loop.sql
-- The join the ad platform can't make: spend to leads to deals to revenue.

WITH spend AS (
  SELECT channel, SUM(spend) AS spend
  FROM paid_media.ad_spend
  GROUP BY 1
),
outcomes AS (
  SELECT
    l.channel,
    COUNT(DISTINCT l.lead_id)                                  AS leads,
    COUNT(DISTINCT d.deal_id)                                  AS deals,
    COUNT(DISTINCT d.deal_id) FILTER (WHERE d.is_closed_won)   AS wins,
    COALESCE(SUM(d.amount) FILTER (WHERE d.is_closed_won), 0)  AS revenue
  FROM paid_media.leads l
  LEFT JOIN paid_media.deals d ON d.lead_id = l.lead_id
  GROUP BY 1
)
SELECT
  o.channel,
  COALESCE(s.spend, 0)                                      AS spend,
  o.leads,
  ROUND(COALESCE(s.spend, 0) / NULLIF(o.leads, 0), 2)       AS cost_per_lead,
  o.deals,
  ROUND(100.0 * o.deals / NULLIF(o.leads, 0), 1)            AS lead_to_deal_pct,
  o.wins,
  ROUND(COALESCE(s.spend, 0) / NULLIF(o.wins, 0), 0)        AS cost_per_win,
  o.revenue,
  ROUND(o.revenue / NULLIF(s.spend, 0), 2)                  AS revenue_per_ad_dollar
FROM outcomes o
LEFT JOIN spend s USING (channel)
ORDER BY cost_per_lead;

-- Sorted by cost per lead, displaying revenue per ad dollar. Reading left to
-- right, the two cheapest channels return the least.
--
-- lead_to_deal_pct is where it breaks. Meta converts 2.7% of leads into
-- deals, Display 1.6%, LinkedIn 12.2%. The cheap channels are cheap because
-- the leads aren't buyers.


-- Blended, for the scorecard: total paid spend against total revenue from
-- paid-sourced leads.
WITH paid AS (
  SELECT lead_id FROM paid_media.leads WHERE channel <> 'Organic / Direct'
)
SELECT
  (SELECT SUM(spend) FROM paid_media.ad_spend)              AS total_spend,
  SUM(d.amount) FILTER (WHERE d.is_closed_won)              AS paid_revenue,
  ROUND(SUM(d.amount) FILTER (WHERE d.is_closed_won)
        / (SELECT SUM(spend) FROM paid_media.ad_spend), 2)  AS blended_rev_per_ad_dollar
FROM paid_media.deals d
JOIN paid p ON p.lead_id = d.lead_id;
