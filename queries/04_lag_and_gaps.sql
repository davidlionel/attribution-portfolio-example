-- 04_lag_and_gaps.sql
-- Two things that make the headline numbers less certain than they look.


-- 1. Lag. Time from lead created to deal closed won.
SELECT
  l.channel,
  COUNT(*) AS wins,
  ROUND(AVG(d.close_date - l.created_date::date), 0) AS avg_days_lead_to_close
FROM paid_media.leads l
JOIN paid_media.deals d ON d.lead_id = l.lead_id
WHERE d.is_closed_won
GROUP BY 1
ORDER BY avg_days_lead_to_close DESC;

-- Display and LinkedIn average 106 days. Brand averages 60.
--
-- Which means anyone comparing a month's spend against that month's closed
-- revenue is comparing spend to revenue produced by leads from three months
-- earlier. Long-cycle channels look worst in every single month, forever,
-- because their return hasn't arrived yet.


-- 2. Cohort by lead creation month instead, so spend and the revenue it
-- actually produced land in the same row.
WITH monthly_spend AS (
  SELECT DATE_TRUNC('month', month::date) AS cohort_month, channel,
         SUM(spend) AS spend
  FROM paid_media.ad_spend
  GROUP BY 1, 2
),
monthly_revenue AS (
  SELECT DATE_TRUNC('month', l.created_date) AS cohort_month, l.channel,
         COUNT(DISTINCT l.lead_id) AS leads,
         COALESCE(SUM(d.amount) FILTER (WHERE d.is_closed_won), 0) AS revenue
  FROM paid_media.leads l
  LEFT JOIN paid_media.deals d ON d.lead_id = l.lead_id
  GROUP BY 1, 2
)
SELECT
  r.cohort_month,
  r.channel,
  COALESCE(s.spend, 0) AS spend,
  r.leads,
  r.revenue,
  ROUND(r.revenue / NULLIF(s.spend, 0), 2) AS revenue_per_ad_dollar
FROM monthly_revenue r
LEFT JOIN monthly_spend s USING (cohort_month, channel)
ORDER BY r.cohort_month, r.channel;

-- Recent cohorts will look weak in any cohort view. Their deals have not had
-- time to close yet. That is a property of the method, not a finding, and it
-- has to be said out loud or someone will read the last two months as a
-- collapse.


-- 3. The unattributed bucket. Deals with no lead at all.
SELECT
  COUNT(*)                                   AS deals,
  COUNT(*) FILTER (WHERE is_closed_won)      AS wins,
  SUM(amount) FILTER (WHERE is_closed_won)   AS revenue
FROM paid_media.deals
WHERE lead_id IS NULL;

-- 34 deals, 10 wins, $432,250 of revenue that no channel gets credit for.
-- Every per-channel number above is understated by an unknown share of this.
-- It is the error bar on the whole analysis.
