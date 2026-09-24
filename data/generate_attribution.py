"""
Synthetic closed-loop attribution dataset.

Three tables that no ad platform can join on its own:
  ad_spend  - what was spent, by channel, by month
  leads     - what the spend produced
  deals     - what the leads became

Planted pathology: the channel with the lowest cost per lead has the worst
cost per closed dollar. A second, subtler one: deal lag is long enough that
judging a month's spend by that month's revenue is meaningless.
"""

import csv, random
from datetime import datetime, timedelta

random.seed(9142)

START = datetime(2025, 1, 1)
MONTHS = 18
TODAY = datetime(2026, 7, 1)

# channel: (monthly spend range, cost per click, lead conv from click,
#           lead->deal rate, deal->win rate, avg deal size mult, cycle days)
CHANNELS = {
    "Display - Programmatic":   (( 2400,  3800), 0.55, 0.015, 0.014, 0.10, 0.62, (40, 140)),
    "Paid Search - Brand":      (( 1700,  2400), 2.05, 0.055, 0.130, 0.46, 1.05, (18,  75)),
    "Paid Social - Meta":       (( 6000,  8600), 1.05, 0.025, 0.028, 0.16, 0.70, (35, 120)),
    "Paid Search - Non-Brand":  (( 7800, 10500), 4.30, 0.030, 0.085, 0.27, 1.00, (30, 110)),
    "Paid Social - LinkedIn":   (( 5200,  7000), 9.60, 0.055, 0.110, 0.36, 1.35, (45, 165)),
}
ORGANIC = "Organic / Direct"

CAMPAIGNS = {
    "Paid Social - Meta": ["mofu-retarget", "prospecting-lal", "lead-form-broad"],
    "Paid Search - Non-Brand": ["category-terms", "competitor-terms", "solution-terms"],
    "Paid Search - Brand": ["brand-exact", "brand-phrase"],
    "Paid Social - LinkedIn": ["abm-tier1", "jobtitle-targeting", "content-download"],
    "Display - Programmatic": ["retarget-display", "contextual-b2b"],
    ORGANIC: ["none"],
}

FIRST = "Adeola Marcus Priya Tomas Alicia Kenji Siobhan Rafael Ingrid Omar Lena Darius Noor Beatriz Hollis Yusuf Margit Callum Renata Ivo Grace Malik Elodie Cormac Anaya Peter Mei Jonas Estelle Arun".split()
LAST = "Okonkwo Bergstrom Raghunathan Vieira Ferreira Watanabe Mulvaney Castellanos Lindqvist Haddad Novak Farrell Bahri Almeida Whitfield Demir Szabo Doyle Pires Horvat Grant Zhang Aaltonen Moreau Krishnan Iyer Kavanagh Petrov Nwosu Byrne".split()
DOMAINS = "northwind arclight ferrous brightpath cascade meridian quillon tessellate harborview ridgeline solvent anvil copperline dovetail ember foxglove granitepeak halcyon ironwood juniper kestrel lumen marlowe nimbus oakhurst pinnacle quarry redwood saltmarsh thornbury".split()

STAGES = ["Discovery", "Evaluation", "Proposal", "Negotiation", "Closed Won", "Closed Lost"]


def month_start(i):
    y = START.year + (START.month - 1 + i) // 12
    m = (START.month - 1 + i) % 12 + 1
    return datetime(y, m, 1)


# ------------------------------------------------------------------ spend
ad_spend = []
monthly_leads = {}

for i in range(MONTHS):
    ms = month_start(i)
    for ch, (rng, cpc, l_conv, _, _, _, _) in CHANNELS.items():
        # mild seasonality plus a budget shift toward Meta partway through
        mult = 1.0 + 0.10 * random.uniform(-1, 1)
        if ch == "Paid Social - Meta" and i >= 8:
            mult *= 1.35
        if ch == "Paid Social - LinkedIn" and i >= 8:
            mult *= 0.80
        spend = round(random.uniform(*rng) * mult, 2)
        clicks = int(spend / cpc * random.uniform(0.92, 1.08))
        impressions = int(clicks / random.uniform(0.004, 0.021))
        n_leads = max(1, int(clicks * l_conv * random.uniform(0.85, 1.15)))
        ad_spend.append({
            "month": ms.strftime("%Y-%m-01"),
            "channel": ch,
            "spend": spend,
            "impressions": impressions,
            "clicks": clicks,
        })
        monthly_leads[(i, ch)] = n_leads
    monthly_leads[(i, ORGANIC)] = int(random.uniform(24, 40))

# ------------------------------------------------------------------ leads
leads, deals = [], []
lid = dl = 0

for i in range(MONTHS):
    ms = month_start(i)
    nxt = month_start(i + 1)
    span = (nxt - ms).days
    for ch in list(CHANNELS) + [ORGANIC]:
        for _ in range(monthly_leads[(i, ch)]):
            lid += 1
            created = ms + timedelta(days=random.randrange(span),
                                     hours=random.randint(7, 20),
                                     minutes=random.choice([0, 15, 30, 45]))
            fn, ln = random.choice(FIRST), random.choice(LAST)
            dom = random.choice(DOMAINS) + ".com"

            if ch == ORGANIC:
                d_rate, w_rate, size, cyc = 0.115, 0.34, 1.10, (25, 95)
            else:
                _, _, _, d_rate, w_rate, size, cyc = CHANNELS[ch]

            became_deal = random.random() < d_rate
            leads.append({
                "lead_id": f"L{lid:06d}",
                "created_date": created.strftime("%Y-%m-%d %H:%M:%S"),
                "first_name": fn,
                "last_name": ln,
                "email": f"{fn.lower()}.{ln.lower()}@{dom}",
                "company_domain": dom,
                "channel": ch,
                "campaign": random.choice(CAMPAIGNS[ch]),
                "became_deal": "true" if became_deal else "false",
            })

            if not became_deal:
                continue

            dl += 1
            lag = random.randint(2, 21)
            d_created = created + timedelta(days=lag)
            cycle = random.randint(*cyc)
            close_dt = d_created + timedelta(days=cycle)

            amount = round(random.uniform(9000, 68000) * size / 250) * 250

            if close_dt > TODAY:
                stage = random.choice(["Discovery", "Evaluation", "Proposal", "Negotiation"])
                closed, won, close_str = "false", "false", ""
            else:
                won_flag = random.random() < w_rate
                stage = "Closed Won" if won_flag else "Closed Lost"
                closed, won = "true", ("true" if won_flag else "false")
                close_str = close_dt.strftime("%Y-%m-%d")

            deals.append({
                "deal_id": f"D{dl:05d}",
                "lead_id": f"L{lid:06d}",
                "deal_created_date": d_created.strftime("%Y-%m-%d"),
                "stage": stage,
                "amount": amount if closed == "true" and won == "true" else amount,
                "is_closed": closed,
                "is_closed_won": won,
                "close_date": close_str,
            })

# a slice of deals arrive with no traceable lead: the unattributed bucket
for _ in range(34):
    dl += 1
    d_created = START + timedelta(days=random.randint(20, (TODAY - START).days - 40))
    cycle = random.randint(25, 130)
    close_dt = d_created + timedelta(days=cycle)
    amount = round(random.uniform(11000, 74000) / 250) * 250
    if close_dt > TODAY:
        stage, closed, won, close_str = random.choice(STAGES[:4]), "false", "false", ""
    else:
        won_flag = random.random() < 0.31
        stage = "Closed Won" if won_flag else "Closed Lost"
        closed, won = "true", ("true" if won_flag else "false")
        close_str = close_dt.strftime("%Y-%m-%d")
    deals.append({
        "deal_id": f"D{dl:05d}",
        "lead_id": "",
        "deal_created_date": d_created.strftime("%Y-%m-%d"),
        "stage": stage,
        "amount": amount,
        "is_closed": closed,
        "is_closed_won": won,
        "close_date": close_str,
    })

random.shuffle(deals)


def write(path, rows):
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)


write("/home/claude/attr_ad_spend.csv", ad_spend)
write("/home/claude/attr_leads.csv", leads)
write("/home/claude/attr_deals.csv", deals)
print("spend", len(ad_spend), "| leads", len(leads), "| deals", len(deals))
