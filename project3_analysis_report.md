# Project 3: SQL Data Analysis

**Dataset:** `Dataset for Data Analytics (1).xlsx`  
**Worksheet:** `Sheet1`  
**Database engine:** MySQL 8.0+  
**Table name:** `orders`  
**Analyst:** Data Analyst (automated analysis workflow)  
**Analysis tooling:** Python `openpyxl` for reading/verifying the workbook, MySQL-compatible SQL for the analysis layer

---

## 1. Introduction

This project analyzes a 1,200-record e-commerce orders dataset using SQL. The workbook contains one worksheet with 14 columns covering orders placed between **1 January 2023 and 30 June 2025**. The goal is to turn raw transactional records into clear business answers about revenue, products, customers, payment behaviour, order status, coupons, and acquisition channels.

The original Excel file was **not modified or deleted**. All SQL scripts are written for **MySQL** and are ready to run manually in MySQL Workbench. No live MySQL connection was assumed or required; the queries were prepared for the user to execute after importing the workbook.

---

## 2. Project Objectives

1. Inspect the Excel workbook and document its real structure, column names, data types, record count, missing values, and duplicates.
2. Build a clean MySQL table that matches the dataset exactly.
3. Write MySQL-compatible queries using:
   - `SELECT` to retrieve records
   - `WHERE` to filter records
   - `ORDER BY` to sort records
   - `GROUP BY` to summarize categories
   - `COUNT`, `SUM`, and `AVG` to calculate totals and averages
4. Produce additional business insights on revenue quality, customer behaviour, product performance, and acquisition channels.
5. Document the findings with actual, verified numbers from the dataset.

---

## 3. Dataset Overview

| Property | Value |
|---|---|
| Source file | `Dataset for Data Analytics (1).xlsx` |
| Worksheet | `Sheet1` (only worksheet) |
| Total records | **1,200** (excluding the header row) |
| Total columns | **14** |
| Date range | **2023-01-01 to 2025-06-30** |
| Unique customers | **1,189** |
| Unique products | **7** |
| Payment methods | **5** |
| Order statuses | **5** |
| Referral sources | **5** |
| Unique shipping addresses | 655 |
| Exact duplicate rows | **0** |

### 3.1 Column profile

| # | Column | Excel type detected | MySQL type | Missing | Unique values |
|---|---|---|---|---|---|
| 1 | `OrderID` | Text | `VARCHAR(20)` | 0 | 1,200 |
| 2 | `Date` | Datetime (midnight) | `DATE` | 0 | 671 |
| 3 | `CustomerID` | Text | `VARCHAR(20)` | 0 | 1,189 |
| 4 | `Product` | Text | `VARCHAR(50)` | 0 | 7 |
| 5 | `Quantity` | Integer | `INT` | 0 | 5 |
| 6 | `UnitPrice` | Decimal / integer | `DECIMAL(10,2)` | 0 | 1,193 |
| 7 | `ShippingAddress` | Text | `VARCHAR(255)` | 0 | 655 |
| 8 | `PaymentMethod` | Text | `VARCHAR(50)` | 0 | 5 |
| 9 | `OrderStatus` | Text | `VARCHAR(50)` | 0 | 5 |
| 10 | `TrackingNumber` | Text | `VARCHAR(50)` | 0 | 1,200 |
| 11 | `ItemsInCart` | Integer | `INT` | 0 | 10 |
| 12 | `CouponCode` | Text | `VARCHAR(50) NULL` | **309** | 3 |
| 13 | `ReferralSource` | Text | `VARCHAR(50)` | 0 | 5 |
| 14 | `TotalPrice` | Decimal / integer | `DECIMAL(12,2)` | 0 | 1,195 |

**Category values found in the data**

- **Product:** Chair, Desk, Laptop, Monitor, Phone, Printer, Tablet
- **PaymentMethod:** Cash, Credit Card, Debit Card, Gift Card, Online
- **OrderStatus:** Cancelled, Delivered, Pending, Returned, Shipped
- **ReferralSource:** Email, Facebook, Google, Instagram, Referral
- **CouponCode:** FREESHIP, SAVE10, WINTER15, and 309 blank values

---

## 4. Data Quality Assessment

| Check | Result | Interpretation |
|---|---|---|
| Total records | 1,200 | Complete dataset |
| Total cells | 16,800 | 1,200 × 14 |
| Missing cells | **309** | Only `CouponCode` is missing |
| Missing `CouponCode` | **309 / 1,200 = 25.75%** | Treat blanks as "no coupon used" |
| Missing values in all other columns | **0** | Strong completeness |
| Exact duplicate rows | **0** | No fully duplicated records |
| Duplicate `OrderID` | **0** | Primary key is valid |
| Duplicate `TrackingNumber` | **0** | Tracking numbers are unique |
| `TotalPrice` vs `Quantity × UnitPrice` | **0 mismatches** | Perfect pricing consistency |
| Repeated customers | 11 customers placed 22 orders | Most customers ordered once |

**Conclusion:** The dataset is clean and analysis-ready. The only data-quality issue is the intentionally empty `CouponCode` field, which is best interpreted as "no coupon applied" rather than an error.

---

## 5. How to Import the Excel Data into MySQL

The SQL file `project3_sql_analysis.sql` contains the full table definition and the optional `LOAD DATA` statement. Use one of the two methods below.

### Option A — MySQL Workbench Table Data Import Wizard (recommended)

1. Open **MySQL Workbench** and connect to your local MySQL server.
2. Run the setup section of `project3_sql_analysis.sql` to create the database and table:
   ```sql
   CREATE DATABASE IF NOT EXISTS project3_sql_analysis;
   USE project3_sql_analysis;
   ```
3. In the **Schemas** panel, expand `project3_sql_analysis` → **Tables**.
4. Right-click the `orders` table → **Table Data Import Wizard**.
5. Select `Dataset for Data Analytics (1).xlsx`.
6. Choose the **Sheet1** worksheet.
7. Map the 14 Excel columns to the 14 table columns (they keep the same names).
8. Ensure `Date` is imported as a date and `TotalPrice` / `UnitPrice` as decimal.
9. Click **Next** → **Import**.
10. Verify:
    ```sql
    SELECT COUNT(*) FROM orders;   -- expected 1200
    ```

> If you prefer to let the wizard create the table, that also works, but review the inferred types. Pre-creating the table from the script guarantees the correct `DATE`, `DECIMAL`, and `NULL` definitions.

### Option B — Export Sheet1 to CSV, then `LOAD DATA`

1. In Excel: **File → Save As → CSV UTF-8 (Comma delimited)**, keeping only `Sheet1`.
2. Place the CSV at a known path, for example `C:/Users/Prime/Downloads/orders.csv`.
3. Enable local infile if required (needs the appropriate privilege):
   ```sql
   SET GLOBAL local_infile = 1;
   ```
4. Run the import block at the end of **SECTION 0** in the SQL file:
   ```sql
   LOAD DATA LOCAL INFILE 'C:/Users/Prime/Downloads/orders.csv'
   INTO TABLE orders
   FIELDS TERMINATED BY ',' ENCLOSED BY '"'
   LINES TERMINATED BY '\r\n'
   IGNORE 1 ROWS
   (OrderID, @date_raw, CustomerID, Product, Quantity, UnitPrice,
    ShippingAddress, PaymentMethod, OrderStatus, TrackingNumber,
    ItemsInCart, CouponCode, ReferralSource, TotalPrice)
   SET `Date` = STR_TO_DATE(@date_raw, '%Y-%m-%d');
   ```
5. If Excel exported the date as `MM/DD/YYYY`, change the format string to `'%m/%d/%Y'`.
6. Verify with `SELECT COUNT(*) FROM orders;`.

### Optional clean export with Python

If you prefer a reproducible CSV export, this reads the workbook with `openpyxl` (it does not alter the source file):

```python
import csv
import openpyxl

src = r"C:\Users\Prime\Downloads\Dataset for Data Analytics (1).xlsx"
dst = r"C:\Users\Prime\Downloads\orders.csv"

wb = openpyxl.load_workbook(src, read_only=True, data_only=True)
ws = wb["Sheet1"]

with open(dst, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    for row in ws.iter_rows(values_only=True):
        writer.writerow(row)

wb.close()
print("Exported:", dst)
```

---

## 6. SQL Queries and Explanations

The complete, commented script is in `project3_sql_analysis.sql`. It is organized into ten sections (0–9), with Section 0 covering setup/import and Sections 1–8 covering analysis. Representative queries are shown below.

### 6.1 `SELECT` — retrieve records

```sql
-- All records
SELECT * FROM orders;

-- Selected business columns
SELECT OrderID, `Date`, CustomerID, Product, Quantity,
       UnitPrice, OrderStatus, TotalPrice
FROM orders;

-- First 10 records
SELECT * FROM orders
ORDER BY `Date`, OrderID
LIMIT 10;
```

**Explanation:** `SELECT *` returns every column; the targeted list produces a lighter report. `LIMIT` is useful for a quick post-import sanity check.

### 6.2 `WHERE` — filter records

```sql
-- Delivered orders
SELECT * FROM orders
WHERE OrderStatus = 'Delivered';

-- Orders above 1,000
SELECT * FROM orders
WHERE TotalPrice > 1000
ORDER BY TotalPrice DESC;

-- Laptop orders
SELECT * FROM orders
WHERE Product = 'Laptop';

-- Orders in 2024
SELECT * FROM orders
WHERE `Date` >= '2024-01-01'
  AND `Date` <  '2025-01-01';

-- Orders with no coupon
SELECT * FROM orders
WHERE CouponCode IS NULL;
```

**Explanation:** `WHERE` filters rows before aggregation. `IN`, `BETWEEN`, `LIKE`, `IS NULL`, `AND`, and `OR` are also demonstrated in the script (for example, cancelled/returned orders, Instagram + Online orders, and high-quantity chair/desk orders).

### 6.3 `ORDER BY` — sort records

```sql
-- Highest-value orders first
SELECT OrderID, Product, TotalPrice
FROM orders
ORDER BY TotalPrice DESC;

-- Lowest-value orders first
SELECT OrderID, Product, TotalPrice
FROM orders
ORDER BY TotalPrice ASC;

-- Multi-column sort
SELECT Product, OrderID, TotalPrice
FROM orders
ORDER BY Product ASC, TotalPrice DESC;

-- Top 10 orders
SELECT OrderID, `Date`, Product, TotalPrice
FROM orders
ORDER BY TotalPrice DESC
LIMIT 10;
```

**Explanation:** `ORDER BY` sorts the result set. `DESC` is used for "best/highest first", `ASC` for "lowest first", and multiple columns create a stable grouped ordering.

### 6.4 `GROUP BY` with `COUNT`, `SUM`, and `AVG`

```sql
-- Total orders
SELECT COUNT(*) AS total_orders FROM orders;

-- Total recorded revenue
SELECT SUM(TotalPrice) AS total_revenue FROM orders;

-- Average order value
SELECT AVG(TotalPrice) AS average_order_value FROM orders;

-- Product performance
SELECT Product,
       COUNT(*)                  AS orders,
       SUM(Quantity)             AS units_sold,
       ROUND(SUM(TotalPrice), 2) AS total_revenue,
       ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM orders
GROUP BY Product
ORDER BY total_revenue DESC;

-- Orders by status
SELECT OrderStatus, COUNT(*) AS orders
FROM orders
GROUP BY OrderStatus
ORDER BY orders DESC;

-- Orders by payment method
SELECT PaymentMethod, COUNT(*) AS orders
FROM orders
GROUP BY PaymentMethod
ORDER BY orders DESC;

-- Revenue by referral source
SELECT ReferralSource, ROUND(SUM(TotalPrice), 2) AS total_revenue
FROM orders
GROUP BY ReferralSource
ORDER BY total_revenue DESC;

-- Yearly performance
SELECT YEAR(`Date`) AS order_year,
       COUNT(*) AS orders,
       ROUND(SUM(TotalPrice), 2) AS total_revenue
FROM orders
GROUP BY YEAR(`Date`)
ORDER BY order_year;
```

**Explanation:** `GROUP BY` collapses rows into categories. `COUNT(*)` counts orders, `SUM` adds order value or units, and `AVG` gives the average order value within each category. The script also includes monthly grouping with `DATE_FORMAT`, a product × status pivot, and revenue-share calculations.

### 6.5 Additional business queries

The script also contains:

- Revenue share by status, payment method, product, and referral source
- Fulfilment rate and delivered-only realized revenue
- Top 10 customers by spend and repeat-customer analysis
- Customer order-frequency distribution
- Coupon impact on average order value
- Product revenue ranking (`RANK()`)
- Cancellation/return rate by product
- Month-over-month growth (`LAG()`) and cumulative revenue
- Revenue concentration of the top 10% of orders (`NTILE`)
- Best-selling product per referral source

These require **MySQL 8.0+** for the window-function queries.

> **MySQL compatibility note:** All queries use standard MySQL syntax. The column name `Date` is wrapped in backticks because it is a MySQL keyword. No database connection is assumed; run the script manually in MySQL Workbench.

---

## 7. Actual Findings and Insights

All figures below were calculated from the workbook itself and cross-checked with independent Python calculations.

### 7.1 Headline KPIs

| Metric | Verified result |
|---|---|
| Total orders | **1,200** |
| Total recorded revenue | **1,264,761.96** |
| Average order value | **1,053.97** |
| Median order value | **823.62** |
| Minimum order value | **11.39** |
| Maximum order value | **3,456.40** |
| Total quantity sold | **3,535 units** |
| Average quantity per order | **2.95** |
| Total items in carts | **6,582** |
| Average items in cart | **5.49** |
| Unique customers | **1,189** |
| Repeat customers | **11** (22 orders) |

**Important caveat:** total recorded revenue includes cancelled, returned, and pending orders. It is **not** realized sales. Delivered-only revenue is **242,600.32**, or **19.18%** of recorded value.

### 7.2 Product performance

| Product | Orders | Units | Recorded revenue | Revenue share | Avg order value |
|---|---:|---:|---:|---:|---:|
| Chair | 178 | **562** | **195,620.11** | **15.47%** | 1,098.99 |
| Printer | **181** | 542 | 195,612.61 | 15.47% | 1,080.73 |
| Laptop | 173 | 535 | 192,126.56 | 15.19% | **1,110.56** |
| Tablet | 179 | 497 | 186,568.95 | 14.75% | 1,042.28 |
| Monitor | 163 | 480 | 175,651.41 | 13.89% | 1,077.62 |
| Desk | 170 | 508 | 167,459.93 | 13.24% | 985.06 |
| Phone | 156 | 411 | 151,722.39 | 12.00% | 972.58 |

**Insights**

- **Chair** generated the highest recorded revenue (195,620.11) and the most units (562), but **Printer** had the most orders (181).
- The gap between the highest and lowest revenue products is relatively small: 15.47% versus 12.00%. Revenue is not dominated by a single product.
- **Laptop** has the highest average order value (1,110.56); **Phone** has the lowest (972.58).
- Product-level unit prices range from 11.39 to 699.93, with average unit prices between roughly 329.61 and 375.22.

### 7.3 Payment method performance

| Payment method | Orders | Units | Recorded revenue | Revenue share | Avg order value |
|---|---:|---:|---:|---:|---:|
| Online | **258** | 731 | 262,442.94 | 20.75% | 1,017.22 |
| Cash | 246 | **753** | 259,786.29 | 20.54% | 1,056.04 |
| Credit Card | 234 | 712 | **263,847.63** | **20.86%** | **1,127.55** |
| Debit Card | 232 | 664 | 232,361.18 | 18.37% | 1,001.56 |
| Gift Card | 230 | 675 | 246,323.92 | 19.48% | 1,070.97 |

**Insights**

- **Online** is the most-used method by order count (258).
- **Credit Card** produces the most revenue (263,847.63) and the highest average order value (1,127.55), despite ranking third in order count.
- **Debit Card** has the lowest revenue (232,361.18) and the lowest average order value (1,001.56).
- The five payment methods are fairly balanced: each contributes between 18.37% and 20.86% of recorded revenue.

### 7.4 Order status and revenue quality

| Order status | Orders | Units | Recorded revenue | Revenue share | Avg order value |
|---|---:|---:|---:|---:|---:|
| Cancelled | **250** | 759 | **276,396.21** | **21.85%** | 1,105.58 |
| Returned | 247 | 682 | 243,277.70 | 19.24% | 984.93 |
| Pending | 237 | 724 | 256,328.15 | 20.27% | 1,081.55 |
| Shipped | 235 | 680 | 246,159.58 | 19.46% | 1,047.49 |
| Delivered | 231 | 690 | 242,600.32 | 19.18% | 1,050.22 |

**Insights**

- **Cancelled orders are the largest group by count (250) and by recorded value (276,396.21).** This is the most important risk signal in the dataset.
- Only **231 orders (19.25%)** reached "Delivered". Delivered-only revenue is **242,600.32**, which is just **19.18%** of the 1,264,761.96 recorded.
- **969 orders (80.75%)** are not delivered and account for **1,022,161.64** in recorded value.
- Returned orders are also high at 247; together, cancelled + returned = 497 orders (41.42%).
- These figures should prompt a review of fulfilment, cancellation reasons, and returns handling before treating recorded revenue as actual sales.

### 7.5 Referral source performance

| Referral source | Orders | Units | Recorded revenue | Revenue share | Avg order value |
|---|---:|---:|---:|---:|---:|
| Instagram | **259** | **770** | **275,285.45** | **21.77%** | 1,062.88 |
| Email | 250 | 746 | 261,808.55 | 20.70% | 1,047.23 |
| Google | 241 | 714 | 250,441.48 | 19.80% | 1,039.18 |
| Facebook | 228 | 674 | 250,410.90 | 19.80% | **1,098.29** |
| Referral | 222 | 631 | 226,815.58 | 17.93% | 1,021.69 |

**Insights**

- **Instagram** is the strongest acquisition source by both orders (259) and recorded revenue (275,285.45).
- **Facebook** has the highest average order value (1,098.29) despite the second-lowest order count.
- **Referral** is the weakest source by orders (222) and revenue (226,815.58).
- The spread across sources is moderate (17.93% to 21.77%), so no single channel overwhelmingly dominates.

### 7.6 Coupon analysis

| Coupon | Orders | Units | Recorded revenue | Revenue share | Avg order value |
|---|---:|---:|---:|---:|---:|
| FREESHIP | **313** | 914 | **335,036.99** | **26.49%** | 1,070.41 |
| No coupon | 309 | **941** | 322,401.41 | 25.49% | 1,043.37 |
| WINTER15 | 292 | 836 | 302,483.54 | 23.92% | 1,035.90 |
| SAVE10 | 286 | 844 | 304,840.02 | 24.10% | 1,065.87 |

**Insights**

- **74.25% of orders (891 / 1,200)** used a coupon; only 309 had no coupon.
- **FREESHIP** is the most-used coupon (313 orders) and generated the highest revenue (335,036.99).
- Average order value with a coupon is **1,057.64**, versus **1,043.37** without a coupon — a small difference of 14.27. Coupons are therefore not associated with lower order value in this dataset, but this is a descriptive comparison, not a causal result.
- The high coupon-usage rate suggests promotions are a major part of the sales mix.

### 7.7 Time-based performance

| Year | Orders | Units | Recorded revenue | Revenue share | Avg order value |
|---|---:|---:|---:|---:|---:|
| 2023 | **510** | 1,524 | **552,643.24** | **43.70%** | 1,083.61 |
| 2024 | 459 | 1,351 | 480,235.87 | 37.97% | 1,046.27 |
| 2025 | 231 | 660 | 231,882.85 | 18.33% | 1,003.82 |

**Insights**

- **2025 covers January–June only**, so its lower totals are not directly comparable with full years.
- Comparing the two full years: revenue fell from **552,643.24 in 2023** to **480,235.87 in 2024**, a decline of **13.10%**; orders fell from **510 to 459**, a decline of **10.00%**.
- **2023-05** (63,836.84) and **2024-06** (68,068.54) were strong months. **2024-06** was the highest-revenue month overall.
- **2023-04** was the lowest-revenue month (27,751.71, 31 orders). The fewest orders were placed in **2025-01** (27 orders).
- Orders average about **1.79 per day**; the busiest single day was **2023-08-20** with 8 orders.

### 7.8 Customer behaviour

- **1,189 unique customers** across 1,200 orders — almost every customer ordered once.
- Only **11 customers** placed more than one order, contributing **22 orders** (1.83% of all orders).
- The top customer is **C38840** with **2 orders** and **5,723.23** in recorded spend.
- Apart from the top customer (C38840, 5,723.23), the remaining top-10 customers are single-order buyers with recorded spend between **3,313.90 and 3,456.40**.
- The **top 10% of orders** account for **26.26%** of recorded revenue; the **top 20%** account for **45.49%**. Revenue is moderately concentrated, not extremely skewed.

### 7.9 Single-order extremes

| OrderID | Date | Product | Quantity | UnitPrice | TotalPrice |
|---|---|---|---:|---:|---:|
| ORD200789 | 2023-08-17 | Tablet | 5 | 691.28 | **3,456.40** |
| ORD201122 | 2023-06-07 | Monitor | 5 | 678.19 | 3,390.95 |
| ORD200632 | 2023-05-02 | Laptop | 5 | 678.16 | 3,390.80 |
| ORD200469 | 2023-11-26 | Chair | 5 | 676.98 | 3,384.90 |
| ORD200328 | 2023-02-28 | Tablet | 5 | 674.04 | 3,370.20 |

The largest order is relatively modest compared with total revenue (0.27%), reinforcing that the business is not dependent on a few huge transactions.

---

## 8. Conclusion

The dataset is clean, complete, and highly suitable for SQL analysis. The workbook contains 1,200 orders and 14 columns, with no duplicate records and no missing values outside the optional `CouponCode` field. Pricing is internally consistent: `TotalPrice` equals `Quantity × UnitPrice` for every record.

SQL aggregation shows that recorded revenue is spread fairly evenly across seven products, five payment methods, and five referral sources. **Chair** leads revenue, **Printer** leads order count, **Online** leads payment usage, and **Instagram** leads acquisition. However, the most important business finding is the **order-status mix**: only **19.25% of orders were delivered**, while cancelled orders alone hold **21.85%** of recorded value. This means recorded revenue substantially overstates realized sales, and fulfilment/returns performance should be the first area for operational review.

The analysis also shows that full-year revenue declined **13.10%** from 2023 to 2024, coupon usage is very high (74.25% of orders), and repeat purchasing is almost non-existent (11 repeat customers out of 1,189). These findings provide a clear starting point for deeper work on retention, promotion effectiveness, and fulfilment quality.

The SQL script in `project3_sql_analysis.sql` can be run directly in MySQL Workbench after importing the workbook, and `dataset_summary.csv` provides a compact, reusable summary of the dataset and its statistics.

---

## 9. Deliverables

| File | Purpose |
|---|---|
| `project3_sql_analysis.sql` | Complete MySQL script: table creation, import notes, SELECT/WHERE/ORDER BY/GROUP BY/COUNT/SUM/AVG queries, business insights, verification queries |
| `project3_analysis_report.md` | This report: introduction, objectives, dataset overview, query explanations, verified findings, conclusion |
| `dataset_summary.csv` | Long-format summary of the dataset: overview, column profile, numeric statistics, categorical breakdowns, time analysis, customer analysis, and key findings |

**Source file (unchanged):** `C:\Users\Prime\Downloads\Dataset for Data Analytics (1).xlsx`
