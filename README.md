# olist
End-to-end analytics pipeline on the Olist Brazilian e-commerce dataset: Python and MySQL to Power BI.
(about 99,000 orders, 2016 to October 2018). It answers one question: **how often do orders arrive later than promised, where does it happen, and does it hurt customer reviews?**

The pipeline runs from raw CSV files to a dashboard: Python cleans and loads the data, MySQL stores it and answers the business questions through SQL views, and Power BI presents the results.

**Tools:** Python (Pandas, SQLAlchemy, PyMySQL), MySQL, SQL (CTEs, window functions, views), Power BI
<img width="1303" height="727" alt="Screenshot 2026-10-23 173732" src="https://github.com/user-attachments/assets/fc7d1944-c2e0-4671-9ed7-4a9900c90be5" />


## Key findings

- **6.8% of delivered orders arrived late** (6,534 of 96,470 delivered orders with a recorded delivery date).
- **Late orders score about 2 points lower.** The average review score is 4.29 for on-time orders and 2.27 for late orders.
- **Review scores fall as the delay grows:**

| Delivery vs estimated date | Avg review score |
|---|---|
| On time or early | 4.29 |
| 1-3 days late | 3.29 |
| 4-7 days late | 2.10 |
| 8+ days late | 1.70 |

  Orders 8+ days late make up about 44% of all late orders.
- **Late rates vary a lot by state**, from 2.8% to 21.4%. The highest are AL (21.4%), MA (17.4%) and SE (15.2%). SP has the lowest rate among large states (4.5%).
- **Rate and volume tell different stories.** SP has the most late orders (1,820) only because it has the most orders. SP and RJ together account for about half of all late orders. RJ combines a high rate (12.1%) with 1,495 late orders and a lower average review score than SP (3.97 vs 4.25).
- **The high-late states are not simply under-promised.** Customers in AL, MA and SE are promised 31 to 33 days on average, against 19.8 in SP, yet they still receive orders late. This points to slow delivery in those states, not unrealistically short estimates.


## Recommendations

**1. Prioritise Rio de Janeiro (RJ) for delivery improvement.**
RJ has 1,495 late orders (12.1% late rate), the second-highest count after SP,
and a late rate nearly three times SP's. Its average review score is 3.97,
against 4.25 in SP. If RJ matched SP's late rate (4.5%) at the same order
volume, late orders would fall by about 940, roughly 14% of all late orders.
SP is not the priority: its 1,820 late orders reflect volume (40,494 orders),
and its late rate is already among the lowest.

**2. Investigate delivery performance in AL, MA and SE.**
These states have the highest late rates (21.4%, 17.4%, 15.2%) even though
customers are already promised 31 to 33 days on average, against 19.8 in SP, so estimates are not unrealistically short. Actual delivery takes roughly 22 to 25 days there, using about 70 to 75% of the promised time (SP: about 44%). This points to slow delivery (carrier transit or seller dispatch). Splitting each order into seller-handling time and carrier
transit time would show which stage is responsible.

**3. Flag orders at risk of running 8+ days past the estimate.**
Orders 8+ days late are 44% of all late orders and score 1.70 on average,
against 4.29 for on-time orders. Proactive communication or escalation for
these orders targets the worst customer outcomes.


## Pipeline

```
Olist CSV files  ->  Python (clean and load)  ->  MySQL (olist database)
                 ->  SQL views (analysis)     ->  Power BI dashboard
```

1. **Python:** reads the CSV files, profiles and cleans each table, and writes the cleaned tables to MySQL with SQLAlchemy.
2. **MySQL:** the single source of truth. All business logic lives in SQL.
3. **SQL views:** each analysis is saved as a view so the results are reproducible.
4. **Power BI:** connects to the views and presents the findings on one page.

## Data

Source: [Olist Brazilian E-Commerce dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

Seven tables are used: customers, orders, order items, payments, reviews, products and sellers, plus the category name translation file. The geolocation table was left out on purpose: it has over a million rows and is not needed for this question.

## Data cleaning (Python)

- Converted the five order date columns to proper datetimes.
- Kept missing delivery, approval and carrier dates as NULL. They carry real information (canceled, unavailable or in-transit orders), so they were not filled with placeholder values.
- Checked that foreign keys line up across tables (for example, every item's product exists in the products table).
- Checked order timelines for impossible sequences (for example, approval before purchase).
- Fixed the misspelled `lenght` column names in the products table.
- Stored zip code prefixes as text with leading zeros restored.
- Loaded each table into MySQL with fixed-length ID columns (`VARCHAR(50)`) and added indexes on the join keys.
- Verified that row counts in MySQL match the cleaned DataFrames.

## SQL analysis

All SQL is in the `sql/` folder.

**`order_base`** is the foundation view, with exactly one row per order. Orders link to several items, payments and reviews, so joining those tables directly would multiply rows and inflate totals. Each of those tables is therefore aggregated to one row per order in a CTE before being joined to `orders`. Checks: the row count equals the orders table, and total item revenue matches the sum of `price` in `order_items`.

Its calculated columns:
- `delivery_days`: purchase to delivery
- `delay_days`: delivery date minus estimated delivery date (positive means late)
- `is_late`: 1 if delivered after the estimated date, 0 if not, NULL if undelivered

Views built on top of it:

| View | Purpose |
|---|---|
| `late_vs_ontime` | Average review score for late vs on-time orders |
| `delay_category` | Review score by delay bucket |
| `state_wise_analysis` | Late rate, late orders, promised and actual delivery time and score by state |
| `state_wise_rank` | Top 3 sellers by revenue in each state |

SQL techniques used: CTEs, joins, aggregation, `CASE` expressions, window functions (`ROW_NUMBER`, `RANK` with `PARTITION BY`) and views.

## Dashboard (Power BI)

A single page connected to the MySQL views, showing the headline late rate and review scores, review score by delay bucket, late rate by state, and top sellers with a state filter.

## Assumptions and limitations

- **Delivered orders only.** Delay analysis uses orders with status `delivered` and a recorded delivery date. Eight delivered orders have no delivery date and six canceled orders do have one. Both groups were excluded from late-rate calculations.
- **One review per order.** Where an order has more than one review, the most recent one is used. Orders without a review (768) are kept, with no score.
- **"Late" is judged by date.** A delivery is late if its date is after the estimated delivery date. Times of day are ignored, because estimates are stored at midnight.
- **Review timing.** Some review surveys may have been sent before delivery, so a score may not always reflect the delivery experience.
- **Responders only.** Scores come only from customers who left a review.
- **Association, not proof of cause.** Late orders scoring lower does not prove that lateness alone is the cause.
- **State figures are indicative.** States differ in distance and logistics, and some have few orders (for example AL with fewer than 400). States with 100 or fewer delivered orders (AC, AP, RR) were left out of the state comparison.
- **Product categories.** Categories without an English translation keep their Portuguese name, and products with no category are labelled `unknown`.
- **Payments.** [Add one line on how you treated zero-value payments and the `not_defined` payment type.]

## Repository structure

```
.
├── data/                  # raw CSV files (not committed, see Kaggle link)
├── notebooks/
│   └── 01_load_clean.ipynb
├── sql/
│   ├── 02_order_base.sql
│   └── 03_analysis_views.sql
├── dashboard/
│   └── olist_dashboard.pbix
├── images/
│   └── dashboard.png
└── README.md
```

## How to run

1. Download the dataset from Kaggle and place the CSV files in `data/`.
2. Install the packages: `pip install pandas sqlalchemy pymysql cryptography`
3. In MySQL, create the database: `CREATE DATABASE olist;`
4. Run the notebook in `notebooks/`. It asks for your MySQL password when it runs, and no password is stored in the code.
5. Run the SQL files in `sql/` in order to create `order_base` and the analysis views.
6. Open the `.pbix` file in Power BI Desktop and point it at your local `olist` database.
