# The cheapest channel in the account was losing money

18 months of paid media. Two channels have the lowest cost per lead and return roughly a dollar of revenue per dollar spent. The ad platform can't tell you that, because it can't see what closed.

---

## What the ad platform shows

Rank the account by cost per lead and the answer is obvious:

| Channel | Spend | Leads | Cost per lead |
|---|---|---|---|
| Paid Search - Brand | $37,670 | 1,040 | $36 |
| Display - Programmatic | $54,446 | 1,461 | $37 |
| Paid Social - Meta | $146,094 | 3,392 | $43 |
| Paid Search - Non-Brand | $168,518 | 1,141 | $148 |
| Paid Social - LinkedIn | $96,750 | 547 | $177 |

Display and Meta look like the best buys. LinkedIn costs nearly five times as much per lead.

That's as far as any ad platform can take you. A "conversion" in Google Ads or Meta is a form fill. What happened after lives in the CRM and never travels back.

## What the CRM adds

| Channel | Cost/lead | Lead → deal | Wins | Cost per win | Revenue per ad $ |
|---|---|---|---|---|---|
| Paid Search - Brand | $36 | 13.6% | 45 | $837 | **$50.19** |
| Display - Programmatic | $37 | 1.6% | 2 | $27,223 | **$0.79** |
| Paid Social - Meta | $43 | 2.7% | 5 | $29,219 | **$1.13** |
| Paid Search - Non-Brand | $148 | 8.2% | 19 | $8,869 | **$4.80** |
| Paid Social - LinkedIn | $177 | 12.2% | 14 | $6,911 | **$7.13** |

$200,540 went to Display and Meta over 18 months. They produced 7 closed deals between them and returned $208,250.

LinkedIn costs four times more per lead and returns nine times more per dollar.

The break is in the lead-to-deal column. Meta converts 2.7% of its leads into deals, Display 1.6%, LinkedIn 12.2%. The cheap channels are cheap because the leads aren't buyers.

## The caveat that matters

Brand search returns $50 per ad dollar, which makes it look like the best line in the account. It isn't a channel in the same sense as the others. People searching your brand name already knew who you were. Brand search captures demand that something else created.

So "cut Meta, move the budget to brand" doesn't work. Brand volume is capped by how many people already know you, and the channels that create that awareness are the ones being cut to fund it.

## What I'd do

**Stop Display.** $54,446 for two closed deals. There's no version of this where that continues.

**Put Meta on a closed-loop target.** Not a CPL target. If the team is measured on cost per lead, Meta will always win the review and always lose the money.

**Move budget toward LinkedIn and non-brand**, the two channels that actually convert, and watch cost per win rather than cost per lead as you scale them.

**Instrument it so this isn't a one-off.** The analysis is a post-mortem. The fix is passing deal outcomes back into the ad platforms so bidding optimizes toward revenue instead of form fills, and pulling spend into the warehouse alongside CRM data so the join above is a dashboard rather than a project.

---

## Two things this doesn't settle

**Last touch.** Each lead carries one channel. Real buyers touch several. A LinkedIn ad that created awareness and a brand search that captured it get counted once, and brand takes all the credit. So brand is overstated by an unknown amount and the demand-generating channels are understated by the same amount. The direction of the finding holds regardless, since Display and Meta are not plausibly being robbed of thirty times their measured return, but the exact figures would move.

**Unattributed revenue.** 34 deals have no lead record at all: 10 closed won, $432,250. No channel gets credit for any of it. That's the error bar on every number above.

## Lag, and why the monthly view lies

Average days from lead created to closed won:

| Channel | Days |
|---|---|
| Display - Programmatic | 106 |
| Paid Social - LinkedIn | 106 |
| Paid Social - Meta | 101 |
| Paid Search - Non-Brand | 80 |
| Organic / Direct | 76 |
| Paid Search - Brand | 60 |

Comparing a month's spend to that month's closed revenue compares spend to revenue produced by leads from three months earlier. Long-cycle channels look worst in every month, permanently, because their return hasn't arrived yet.

`04_lag_and_gaps.sql` cohorts by lead creation month instead, so spend and the revenue it produced sit in the same row. One consequence worth stating whenever you show it: recent cohorts always look weak, because their deals haven't had time to close. That's a property of the method, not a finding.

---

## Running it

1. Create a Postgres database (Supabase free tier is fine).
2. Load the three CSVs from `/data` into `paid_media.ad_spend`, `paid_media.leads`, `paid_media.deals`.
3. Run `queries/01_setup.sql` through `04_lag_and_gaps.sql` in order.

`01_setup.sql` handles one thing worth knowing about. `deals.lead_id` is blank for the 34 unattributed deals, and a blank is not NULL. If those import as empty strings, the unattributed query returns zero and the gap disappears silently. That's the failure mode this whole project is about: the number looks fine and the thing it's missing is invisible.

## The data

Synthetic. 18 months, 5 paid channels plus organic, 8,134 leads and 512 deals, generated with `data/generate_attribution.py`. No client data is involved.

The channel economics were planted deliberately so the analysis would have something to find. The method is real; the numbers are manufactured. The generator is included so anyone can see exactly what was planted and reproduce the result.
