# WellTrack-Member-Retention-Revenue-Analytics-Platform


## 🎯 Project Overview

FitTrack operates a **B2B2C fitness subscription platform** — selling memberships to corporate clients whose employees access partner gym networks. This project builds the full analytics layer from scratch:

| Deliverable | Description |
|---|---|
| **4-table PostgreSQL schema** | members, invoices, facility_checkins, partner_usage |
| **6 production SQL queries** | MRR trend, churn by tier, cohort retention, engagement scoring, partner utilisation, at-risk export |
| **Interactive Tableau dashboard** | 5 live visualisations mirroring the SQL KPI outputs |
| **Data dictionary** | Full business-rule documentation for every metric |
| **Stakeholder PPT** | Executive presentation with problem → analysis → recommendations |

**Scale:** 4,800+ member records · 12-month time horizon · PostgreSQL 15

---

## 💡 Business Problem

| # | Problem | Business Impact |
|---|---|---|
| 1 | No visibility into **which tier drives churn** | Revenue leak unquantified |
| 2 | **576 members inactive >14 days** with no re-engagement | ~$350k ARR at risk |
| 3 | **73% partner utilisation** — no data on which partners earn their cost | Margin drag unaddressed |
| 4 | Reporting requires ad-hoc analyst requests | Slow decision-making |

**Objective:** Surface actionable revenue intelligence for product and commercial teams through a self-serve analytics layer.

---

## 🗄️ Dataset & Schema

### Entity Relationship Diagram

```
members (PK: member_id)
    │
    ├──── invoices          (FK: member_id)   — monthly subscription payments
    ├──── facility_checkins (FK: member_id)   — gym visit records
    └──── partner_usage     (FK: member_id)   — external partner facility usage
```

### Table Definitions

**`members`**
| Column | Type | Notes |
|---|---|---|
| `member_id` | SERIAL PK | Surrogate key |
| `full_name` | VARCHAR(100) | |
| `email` | VARCHAR(150) UNIQUE | |
| `membership_tier` | ENUM | Basic / Standard / Premium |
| `join_date` | DATE | Used for cohort grouping |
| `status` | ENUM | active / churned / paused |
| `corporate_client_id` | INTEGER | NULL = direct consumer |
| `last_checkin_date` | DATE | Denormalised for performance |
| `monthly_fee` | NUMERIC(8,2) | $29 / $49 / $79 |

**`invoices`**
| Column | Type | Notes |
|---|---|---|
| `invoice_id` | SERIAL PK | |
| `member_id` | INTEGER FK | References members |
| `invoice_date` | DATE | |
| `amount` | NUMERIC(8,2) | |
| `status` | ENUM | paid / unpaid / overdue / refunded |
| `payment_method` | VARCHAR(50) | |
| `billing_period` | VARCHAR(20) | e.g. '2026-05' |

**`facility_checkins`**
| Column | Type | Notes |
|---|---|---|
| `checkin_id` | SERIAL PK | |
| `member_id` | INTEGER FK | |
| `facility_id` | INTEGER FK | |
| `checkin_date` | DATE | |
| `checkin_time` | TIME | |
| `facility_type` | VARCHAR(50) | Gym / Pool / Yoga / CrossFit |
| `duration_mins` | INTEGER | |

**`partner_usage`**
| Column | Type | Notes |
|---|---|---|
| `usage_id` | SERIAL PK | |
| `member_id` | INTEGER FK | |
| `partner_name` | VARCHAR(100) | PureGym / Anytime Fitness etc. |
| `usage_date` | DATE | |
| `visit_count` | INTEGER | |
| `activity_type` | VARCHAR(50) | |
| `cost_to_platform` | NUMERIC(6,2) | Per-visit cost billed by partner |

---

## 📊 KPI Framework — Why These Metrics?

Every KPI maps to a board-level business question:

| KPI | Formula | Business Question |
|---|---|---|
| **MRR** | `SUM(amount) WHERE status='paid'` | Is revenue growing predictably? |
| **Churn Rate** | `churned / active_start × 100` | Where are we losing members — and why? |
| **ARPU** | `MRR / COUNT(active_members)` | Are we monetising efficiently by tier? |
| **Cohort Retention** | `active_in_month_N / cohort_size × 100` | Which join cohorts decay fastest? |
| **Engagement Tier** | `CASE WHEN days_inactive ≤ 7 THEN 'High'…` | Who is at risk of churning right now? |
| **Partner Utilisation** | `DISTINCT partner_users / active_members × 100` | Which partners justify their cost? |
| **at_risk_flag** | `days_inactive > 14 AND status = 'active'` | Ready-made CRM re-engagement list |

### Why these techniques?

- **`LAG()` instead of self-join for MoM growth** — single scan, no doubled I/O
- **CTEs over nested subqueries** — each step is named, readable, and maintainable
- **3-month rolling average on churn** — smooths seasonal spikes for cleaner stakeholder communication
- **`RANK()` over `ROW_NUMBER()` for partners** — tied utilisation rates are shown as joint rank, not arbitrarily ordered

---


## 📈 Key Findings

| # | Finding | Evidence |
|---|---|---|
| **F1** | MRR grew **+20.2% YoY** to $214k, Premium driving 40% of MRR from 28% of members | Query 1 output |
| **F2** | Basic churn (**7.0%**) is **3.3× Premium churn (2.1%)** — largest addressable revenue leak | Query 2 output |
| **F3** | Premium cohorts retain **18% better at month 6** (68% vs 48% Basic) | Query 3 heatmap |
| **F4** | **576 members** (13.6% of active base) flagged at-risk — ~**$350k ARR at risk** | Query 4 + 6 |
| **F5** | Top 2 partners (PureGym + Anytime Fitness) account for **50.6%** of all visits — concentration risk | Query 5 output |

---

## ✅ Recommendations

| Priority | Action | Expected Impact |
|---|---|---|
| 🔴 **High — Immediate** | Export 576 at-risk members to CRM, launch re-engagement campaign (free PT session / partner guest pass) | If 30% re-engage: ~$5k MRR protected |
| 🔴 **High — 30 days** | Build Basic → Standard upsell funnel triggered at month 3 | 200 upgrades = +$4k/month MRR |
| 🟡 **Medium — 60 days** | Renegotiate PureGym & top partner contracts using volume data; de-prioritise bottom-2 partners | 8–12% reduction in partner cost line |
| 🟢 **Ongoing** | Schedule 6 queries as weekly dbt jobs; add Tableau alerts (churn >6%, at-risk >600) | Proactive vs reactive — catches issues 4–6 weeks earlier |

---

## 📊 Query Results Summary

```
KPI SNAPSHOT (full 4,800-member dataset)
─────────────────────────────────────────────────────────
Monthly Recurring Revenue (MRR)   : $214,000   ↑ +3.2% MoM
Active Members                    : 4,231       of 4,800 total
Overall Churn Rate                : 4.8%        monthly average
  └─ Premium tier churn           : 2.1%
  └─ Standard tier churn          : 4.6%
  └─ Basic tier churn             : 7.0%        ← 3.3× Premium
ARPU                              : $50.60      avg per active user
At-Risk Members (>14 days inactive): 576         = $349,949 ARR at risk
Partner Utilisation Rate          : 73%          of active members

ENGAGEMENT DISTRIBUTION (4,231 active members)
─────────────────────────────────────────────────────────
  High     (≤7 days inactive)  : 1,820  43.0%
  Medium   (8–14 days)         : 1,080  25.5%
  Low      (15–60 days)        :   755  17.9%
  Inactive (>60 days)          :   576  13.6%  ← at_risk_flag = 1

COHORT RETENTION AT MONTH 6
─────────────────────────────────────────────────────────
  Premium tier  : ~68% retained
  Basic tier    : ~48% retained
  Gap           : 18 percentage points
```

---

## 📁 Project Structure

```
fittrack-analytics/
│
├── README.md                          ← You are here
│
├── sql/
│   ├── 00_schema.sql                  ← DDL: table definitions + indexes
│   ├── 01_seed_data.sql               ← Raw dataset (representative sample)
│   ├── 02_query_mrr_trend.sql         ← Query 1: MRR by tier, 12 months
│   ├── 03_query_churn_by_tier.sql     ← Query 2: Churn rate + 3M rolling avg
│   ├── 04_query_cohort_retention.sql  ← Query 3: 12-month cohort heatmap
│   ├── 05_query_engagement_score.sql  ← Query 4: Engagement CASE scoring
│   ├── 06_query_partner_util.sql      ← Query 5: Partner utilisation + RANK()
│   ├── 07_query_at_risk_export.sql    ← Query 6: Churn-prevention CRM list
│   └── 08_data_dictionary_view.sql    ← Queryable KPI documentation view
│
├── fittrack_analytics_complete.sql    ← All of the above in one file
│
├── docs/
│   ├── FitTrack_Stakeholder_Report.pptx   ← Executive presentation
│   ├── data_dictionary.md                 ← KPI definitions reference
│   └── erd_diagram.png                    ← Entity relationship diagram
│
└── tableau/
    └── fittrack_dashboard.twbx            ← Tableau workbook (connect to PG)
```


- PostgreSQL 15+


## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| **PostgreSQL 15** | Primary database — schema, indexing, all 6 queries |
| **SQL** | Window functions (LAG, RANK, AVG OVER), CTEs, FILTER aggregation, CASE scoring |
| **Tableau** | Interactive dashboard — 5 visualisations connected to PostgreSQL |
| **Git / GitHub** | Version control and portfolio hosting |

### SQL Techniques Used
- `DATE_TRUNC` + `LAG()` — month-over-month growth without self-joins
- Multi-step CTEs — cohort → activity → retention pipeline
- `FILTER (WHERE ...)` — conditional aggregation in a single GROUP BY
- `AVG() OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` — 3-month rolling churn
- `RANK()` window function — partner popularity ranking with ties
- `EXTRACT(MONTH FROM AGE(...))` — months-since-join for cohort analysis
- `NULLIF` — safe division guard
- `COALESCE` — null-safe aggregation in multi-table LEFT JOINs

---


## 🙋 About This Project

Built as a portfolio case study to demonstrate **production-grade SQL and business intelligence skills** for Business analyst.
