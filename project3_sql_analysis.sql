/* =====================================================================
   PROJECT 3: SQL DATA ANALYSIS
   Dataset : Dataset for Data Analytics (1).xlsx
   Worksheet: Sheet1
   Table    : orders
   DB engine: MySQL 8.0+ (all core queries also work in MySQL 5.7)
   Records  : 1,200 orders
   Columns  : 14

   HOW TO USE
   ----------
   1. Open MySQL Workbench and connect to your local server.
   2. Run SECTION 0 to create the database and the `orders` table.
   3. Import the Excel data:
        Option A (recommended): right-click the `orders` table in the
        Schema tree -> "Table Data Import Wizard" -> select the .xlsx file
        -> choose Sheet1 -> map the 14 columns -> Import.
        Option B: export Sheet1 to UTF-8 CSV, then use the LOAD DATA
        statement provided at the end of SECTION 0.
   4. Run the queries section by section. Every query is read-only.
   5. Verify the row count with:
        SELECT COUNT(*) FROM orders;   -- expected: 1200

   NOTES
   -----
   * The original Excel file is NOT modified by this script.
   * `Date` is a MySQL keyword, so it is wrapped in backticks.
   * TotalPrice in this dataset always equals Quantity * UnitPrice
     (verified for all 1,200 records).
   * "Revenue" below means recorded order value. It includes cancelled,
     returned and pending orders, so it is NOT realized sales.
   * Window-function queries (SECTION 8) require MySQL 8.0+.
   ===================================================================== */


/* =====================================================================
   SECTION 0 - DATABASE AND TABLE SETUP
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS project3_sql_analysis;
USE project3_sql_analysis;

-- Uncomment the next line only if you want a clean re-import.
-- DROP TABLE IF EXISTS orders;

CREATE TABLE IF NOT EXISTS orders (
    OrderID         VARCHAR(20)     NOT NULL,
    `Date`          DATE            NOT NULL,
    CustomerID      VARCHAR(20)     NOT NULL,
    Product         VARCHAR(50)     NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(10,2)   NOT NULL,
    ShippingAddress VARCHAR(255)    NOT NULL,
    PaymentMethod   VARCHAR(50)     NOT NULL,
    OrderStatus     VARCHAR(50)     NOT NULL,
    TrackingNumber  VARCHAR(50)     NOT NULL,
    ItemsInCart     INT             NOT NULL,
    CouponCode      VARCHAR(50)     NULL,
    ReferralSource  VARCHAR(50)     NOT NULL,
    TotalPrice      DECIMAL(12,2)   NOT NULL,
    PRIMARY KEY (OrderID),
    UNIQUE KEY uq_tracking (TrackingNumber),
    KEY idx_orders_date (`Date`),
    KEY idx_orders_customer (CustomerID),
    KEY idx_orders_product (Product),
    KEY idx_orders_status (OrderStatus),
    KEY idx_orders_payment (PaymentMethod),
    KEY idx_orders_referral (ReferralSource)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- OPTIONAL: bulk import from a UTF-8 CSV exported from Sheet1.
-- The CSV must contain the header row and the same 14 columns in order.
-- On Windows/MySQL Workbench, enable local infile first if needed:
--   SET GLOBAL local_infile = 1;
--
-- LOAD DATA LOCAL INFILE 'C:/path/to/orders.csv'
-- INTO TABLE orders
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 ROWS
-- (OrderID, @date_raw, CustomerID, Product, Quantity, UnitPrice,
--  ShippingAddress, PaymentMethod, OrderStatus, TrackingNumber,
--  ItemsInCart, CouponCode, ReferralSource, TotalPrice)
-- SET `Date` = STR_TO_DATE(@date_raw, '%Y-%m-%d');


/* =====================================================================
   SECTION 1 - SELECT: RETRIEVE RECORDS
   ===================================================================== */

-- 1.1 Show every column and every record (sample of the full dataset).
SELECT *
FROM orders;

-- 1.2 Show only the columns needed for a lightweight order report.
SELECT OrderID,
       `Date`,
       CustomerID,
       Product,
       Quantity,
       UnitPrice,
       OrderStatus,
       TotalPrice
FROM orders;

-- 1.3 Preview the first 10 records (useful after import).
SELECT *
FROM orders
ORDER BY `Date`, OrderID
LIMIT 10;


/* =====================================================================
   SECTION 2 - WHERE: FILTER RECORDS
   ===================================================================== */

-- 2.1 All delivered orders.
SELECT *
FROM orders
WHERE OrderStatus = 'Delivered';

-- 2.2 Orders with a recorded value above 1,000.
SELECT *
FROM orders
WHERE TotalPrice > 1000
ORDER BY TotalPrice DESC;

-- 2.3 All laptop orders.
SELECT *
FROM orders
WHERE Product = 'Laptop';

-- 2.4 Orders placed in 2024 (date-range filter).
SELECT *
FROM orders
WHERE `Date` >= '2024-01-01'
  AND `Date` <  '2025-01-01'
ORDER BY `Date`;

-- 2.5 Cancelled or returned orders, highest value first.
SELECT OrderID, Product, OrderStatus, TotalPrice
FROM orders
WHERE OrderStatus IN ('Cancelled', 'Returned')
ORDER BY TotalPrice DESC;

-- 2.6 Orders with no coupon code (the only column with missing values).
SELECT *
FROM orders
WHERE CouponCode IS NULL;

-- 2.7 Instagram orders paid online (AND condition).
SELECT OrderID, `Date`, Product, PaymentMethod, ReferralSource, TotalPrice
FROM orders
WHERE ReferralSource = 'Instagram'
  AND PaymentMethod = 'Online'
ORDER BY TotalPrice DESC;

-- 2.8 Delivered OR shipped orders worth more than 2,000.
SELECT OrderID, OrderStatus, Product, TotalPrice
FROM orders
WHERE OrderStatus IN ('Delivered', 'Shipped')
  AND TotalPrice > 2000
ORDER BY TotalPrice DESC;

-- 2.9 Orders containing a coupon code (non-missing values).
SELECT OrderID, CouponCode, TotalPrice
FROM orders
WHERE CouponCode IS NOT NULL
ORDER BY TotalPrice DESC;

-- 2.10 High-quantity orders (4 or 5 units) for chairs or desks.
SELECT OrderID, Product, Quantity, UnitPrice, TotalPrice
FROM orders
WHERE Quantity BETWEEN 4 AND 5
  AND Product IN ('Chair', 'Desk')
ORDER BY Quantity DESC, TotalPrice DESC;


/* =====================================================================
   SECTION 3 - ORDER BY: SORT RECORDS
   ===================================================================== */

-- 3.1 Highest-value orders first.
SELECT OrderID, `Date`, Product, Quantity, TotalPrice
FROM orders
ORDER BY TotalPrice DESC;

-- 3.2 Lowest-value orders first.
SELECT OrderID, `Date`, Product, Quantity, TotalPrice
FROM orders
ORDER BY TotalPrice ASC;

-- 3.3 Sort by product, then by order value (multi-column sort).
SELECT Product, OrderID, `Date`, TotalPrice
FROM orders
ORDER BY Product ASC, TotalPrice DESC;

-- 3.4 Most recent orders first.
SELECT OrderID, `Date`, Product, TotalPrice
FROM orders
ORDER BY `Date` DESC, OrderID DESC;

-- 3.5 Top 10 single orders by recorded value.
SELECT OrderID, `Date`, CustomerID, Product, Quantity, UnitPrice, TotalPrice
FROM orders
ORDER BY TotalPrice DESC
LIMIT 10;


/* =====================================================================
   SECTION 4 - COUNT: CALCULATE TOTALS / FREQUENCIES
   ===================================================================== */

-- 4.1 Total number of orders.
SELECT COUNT(*) AS total_orders
FROM orders;

-- 4.2 Number of distinct customers.
SELECT COUNT(DISTINCT CustomerID) AS unique_customers
FROM orders;

-- 4.3 Number of distinct products and payment methods.
SELECT COUNT(DISTINCT Product)       AS unique_products,
       COUNT(DISTINCT PaymentMethod) AS payment_methods
FROM orders;

-- 4.4 Order count by status.
SELECT OrderStatus,
       COUNT(*) AS order_count
FROM orders
GROUP BY OrderStatus
ORDER BY order_count DESC;

-- 4.5 Order count by product.
SELECT Product,
       COUNT(*) AS order_count
FROM orders
GROUP BY Product
ORDER BY order_count DESC;

-- 4.6 Count of records with a missing coupon code.
SELECT COUNT(*) AS missing_coupon_orders
FROM orders
WHERE CouponCode IS NULL;


/* =====================================================================
   SECTION 5 - SUM: TOTAL NUMERICAL COLUMNS
   ===================================================================== */

-- 5.1 Total recorded revenue across all orders.
SELECT SUM(TotalPrice) AS total_revenue
FROM orders;

-- 5.2 Total number of units sold.
SELECT SUM(Quantity) AS total_units
FROM orders;

-- 5.3 Total items placed in carts.
SELECT SUM(ItemsInCart) AS total_items_in_cart
FROM orders;

-- 5.4 Recorded revenue by product.
SELECT Product,
       SUM(TotalPrice) AS total_revenue
FROM orders
GROUP BY Product
ORDER BY total_revenue DESC;

-- 5.5 Recorded revenue by order status.
SELECT OrderStatus,
       SUM(TotalPrice) AS total_revenue
FROM orders
GROUP BY OrderStatus
ORDER BY total_revenue DESC;

-- 5.6 Recorded revenue and units by payment method.
SELECT PaymentMethod,
       SUM(TotalPrice) AS total_revenue,
       SUM(Quantity)   AS units_sold
FROM orders
GROUP BY PaymentMethod
ORDER BY total_revenue DESC;


/* =====================================================================
   SECTION 6 - AVG: CALCULATE AVERAGES
   ===================================================================== */

-- 6.1 Average order value (AOV).
SELECT AVG(TotalPrice) AS average_order_value
FROM orders;

-- 6.2 Average quantity per order.
SELECT AVG(Quantity) AS average_quantity
FROM orders;

-- 6.3 Average unit price and average items in cart.
SELECT AVG(UnitPrice)   AS average_unit_price,
       AVG(ItemsInCart) AS average_items_in_cart
FROM orders;

-- 6.4 Average order value by product.
SELECT Product,
       AVG(TotalPrice) AS average_order_value
FROM orders
GROUP BY Product
ORDER BY average_order_value DESC;

-- 6.5 Average order value by payment method.
SELECT PaymentMethod,
       ROUND(AVG(TotalPrice), 2) AS average_order_value
FROM orders
GROUP BY PaymentMethod
ORDER BY average_order_value DESC;


/* =====================================================================
   SECTION 7 - GROUP BY: SUMMARIZE CATEGORIES
   ===================================================================== */

-- 7.1 Product performance: orders, units, revenue and AOV.
SELECT Product,
       COUNT(*)                    AS orders,
       SUM(Quantity)               AS units_sold,
       ROUND(SUM(TotalPrice), 2)   AS total_revenue,
       ROUND(AVG(TotalPrice), 2)   AS avg_order_value
FROM orders
GROUP BY Product
ORDER BY total_revenue DESC;

-- 7.2 Payment method performance: orders, revenue share and AOV.
SELECT PaymentMethod,
       COUNT(*)                                                          AS orders,
       ROUND(SUM(TotalPrice), 2)                                         AS total_revenue,
       ROUND(SUM(TotalPrice) * 100.0 / (SELECT SUM(TotalPrice) FROM orders), 2) AS revenue_share_pct,
       ROUND(AVG(TotalPrice), 2)                                         AS avg_order_value
FROM orders
GROUP BY PaymentMethod
ORDER BY total_revenue DESC;

-- 7.3 Order status distribution with revenue share.
SELECT OrderStatus,
       COUNT(*)                                                          AS orders,
       ROUND(SUM(TotalPrice), 2)                                         AS total_revenue,
       ROUND(SUM(TotalPrice) * 100.0 / (SELECT SUM(TotalPrice) FROM orders), 2) AS revenue_share_pct
FROM orders
GROUP BY OrderStatus
ORDER BY orders DESC;

-- 7.4 Referral source performance.
SELECT ReferralSource,
       COUNT(*)                  AS orders,
       SUM(Quantity)             AS units_sold,
       ROUND(SUM(TotalPrice), 2) AS total_revenue,
       ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM orders
GROUP BY ReferralSource
ORDER BY total_revenue DESC;

-- 7.5 Coupon usage (NULL = no coupon code recorded).
SELECT COALESCE(CouponCode, 'No coupon') AS coupon_code,
       COUNT(*)                          AS orders,
       ROUND(SUM(TotalPrice), 2)         AS total_revenue,
       ROUND(AVG(TotalPrice), 2)         AS avg_order_value
FROM orders
GROUP BY COALESCE(CouponCode, 'No coupon')
ORDER BY orders DESC;

-- 7.6 Yearly performance.
SELECT YEAR(`Date`)               AS order_year,
       COUNT(*)                   AS orders,
       SUM(Quantity)              AS units_sold,
       ROUND(SUM(TotalPrice), 2)  AS total_revenue,
       ROUND(AVG(TotalPrice), 2)  AS avg_order_value
FROM orders
GROUP BY YEAR(`Date`)
ORDER BY order_year;

-- 7.7 Monthly performance (YYYY-MM).
SELECT DATE_FORMAT(`Date`, '%Y-%m') AS order_month,
       COUNT(*)                     AS orders,
       ROUND(SUM(TotalPrice), 2)    AS total_revenue
FROM orders
GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY order_month;

-- 7.8 Product x status order counts (pivot-style summary).
SELECT Product,
       SUM(CASE WHEN OrderStatus = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
       SUM(CASE WHEN OrderStatus = 'Shipped'   THEN 1 ELSE 0 END) AS shipped,
       SUM(CASE WHEN OrderStatus = 'Pending'   THEN 1 ELSE 0 END) AS pending,
       SUM(CASE WHEN OrderStatus = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
       SUM(CASE WHEN OrderStatus = 'Returned'  THEN 1 ELSE 0 END) AS returned,
       COUNT(*)                                                    AS total_orders
FROM orders
GROUP BY Product
ORDER BY total_orders DESC;


/* =====================================================================
   SECTION 8 - BUSINESS INSIGHTS
   ===================================================================== */

-- 8.1 Recorded revenue by status with share. Shows how much value is
--     locked in cancelled, returned and pending orders.
SELECT OrderStatus,
       COUNT(*)                                                          AS orders,
       ROUND(SUM(TotalPrice), 2)                                         AS recorded_revenue,
       ROUND(SUM(TotalPrice) * 100.0 / (SELECT SUM(TotalPrice) FROM orders), 2) AS revenue_share_pct
FROM orders
GROUP BY OrderStatus
ORDER BY recorded_revenue DESC;

-- 8.2 Fulfilment rate: share of orders that reached "Delivered".
SELECT COUNT(*) AS total_orders,
       SUM(CASE WHEN OrderStatus = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
       ROUND(SUM(CASE WHEN OrderStatus = 'Delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS delivered_pct
FROM orders;

-- 8.3 Realized revenue (Delivered only) versus recorded revenue.
SELECT ROUND(SUM(CASE WHEN OrderStatus = 'Delivered' THEN TotalPrice ELSE 0 END), 2) AS delivered_revenue,
       ROUND(SUM(TotalPrice), 2)                                                     AS recorded_revenue,
       ROUND(SUM(CASE WHEN OrderStatus = 'Delivered' THEN TotalPrice ELSE 0 END) * 100.0
             / SUM(TotalPrice), 2)                                                   AS delivered_share_pct
FROM orders;

-- 8.4 Top 10 customers by recorded spend.
SELECT CustomerID,
       COUNT(*)                  AS orders,
       ROUND(SUM(TotalPrice), 2) AS total_spend,
       ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM orders
GROUP BY CustomerID
ORDER BY total_spend DESC
LIMIT 10;

-- 8.5 Repeat customers (more than one order).
SELECT CustomerID,
       COUNT(*)                  AS orders,
       ROUND(SUM(TotalPrice), 2) AS total_spend
FROM orders
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY total_spend DESC;

-- 8.6 Customer frequency distribution: how many customers placed 1, 2, ... orders.
SELECT order_count,
       COUNT(*) AS customers
FROM (
    SELECT CustomerID, COUNT(*) AS order_count
    FROM orders
    GROUP BY CustomerID
) AS customer_orders
GROUP BY order_count
ORDER BY order_count;

-- 8.7 Coupon impact: AOV with a coupon versus without a coupon.
SELECT CASE WHEN CouponCode IS NULL THEN 'No coupon' ELSE 'Coupon used' END AS coupon_group,
       COUNT(*)                  AS orders,
       ROUND(AVG(TotalPrice), 2) AS avg_order_value,
       ROUND(SUM(TotalPrice), 2) AS total_revenue
FROM orders
GROUP BY CASE WHEN CouponCode IS NULL THEN 'No coupon' ELSE 'Coupon used' END
ORDER BY coupon_group;

-- 8.8 Product revenue ranking (MySQL 8.0+ window function).
SELECT Product,
       ROUND(SUM(TotalPrice), 2) AS total_revenue,
       RANK() OVER (ORDER BY SUM(TotalPrice) DESC) AS revenue_rank
FROM orders
GROUP BY Product
ORDER BY revenue_rank;

-- 8.9 Cancellation/return rate by product.
SELECT Product,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN OrderStatus IN ('Cancelled', 'Returned') THEN 1 ELSE 0 END) AS cancelled_or_returned,
       ROUND(SUM(CASE WHEN OrderStatus IN ('Cancelled', 'Returned') THEN 1 ELSE 0 END)
             * 100.0 / COUNT(*), 2) AS cancelled_returned_pct
FROM orders
GROUP BY Product
ORDER BY cancelled_returned_pct DESC;

-- 8.10 Month-over-month revenue growth (MySQL 8.0+).
WITH monthly_sales AS (
    SELECT DATE_FORMAT(`Date`, '%Y-%m') AS order_month,
           ROUND(SUM(TotalPrice), 2)    AS revenue
    FROM orders
    GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
)
SELECT order_month,
       revenue,
       LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month))
             * 100.0 / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0), 2) AS mom_growth_pct
FROM monthly_sales
ORDER BY order_month;

-- 8.11 Cumulative revenue by month (MySQL 8.0+).
WITH monthly_sales AS (
    SELECT DATE_FORMAT(`Date`, '%Y-%m') AS order_month,
           ROUND(SUM(TotalPrice), 2)    AS revenue
    FROM orders
    GROUP BY DATE_FORMAT(`Date`, '%Y-%m')
)
SELECT order_month,
       revenue,
       SUM(revenue) OVER (ORDER BY order_month) AS cumulative_revenue
FROM monthly_sales
ORDER BY order_month;

-- 8.12 Revenue concentration: share of revenue generated by the top 10%
--      of orders (MySQL 8.0+).
WITH ranked_orders AS (
    SELECT TotalPrice,
           NTILE(10) OVER (ORDER BY TotalPrice DESC) AS decile
    FROM orders
)
SELECT ROUND(SUM(CASE WHEN decile = 1 THEN TotalPrice ELSE 0 END), 2) AS top_10pct_order_revenue,
       ROUND(SUM(TotalPrice), 2)                                      AS total_revenue,
       ROUND(SUM(CASE WHEN decile = 1 THEN TotalPrice ELSE 0 END)
             * 100.0 / SUM(TotalPrice), 2)                            AS top_10pct_revenue_share
FROM ranked_orders;

-- 8.13 High-value orders per product (orders above the overall AOV).
SELECT Product,
       COUNT(*) AS orders_above_overall_aov,
       ROUND(SUM(TotalPrice), 2) AS revenue_from_above_aov_orders
FROM orders
WHERE TotalPrice > (SELECT AVG(TotalPrice) FROM orders)
GROUP BY Product
ORDER BY revenue_from_above_aov_orders DESC;

-- 8.14 Best-selling product per referral source (MySQL 8.0+).
WITH source_product AS (
    SELECT ReferralSource,
           Product,
           COUNT(*) AS orders,
           RANK() OVER (PARTITION BY ReferralSource ORDER BY COUNT(*) DESC) AS rnk
    FROM orders
    GROUP BY ReferralSource, Product
)
SELECT ReferralSource, Product, orders
FROM source_product
WHERE rnk = 1
ORDER BY ReferralSource;

-- 8.15 Daily order volume and revenue (a compact time-series view).
SELECT `Date`,
       COUNT(*)                  AS orders,
       ROUND(SUM(TotalPrice), 2) AS revenue
FROM orders
GROUP BY `Date`
ORDER BY `Date`;


/* =====================================================================
   SECTION 9 - VERIFICATION QUERIES
   ===================================================================== */

-- 9.1 Expected 1,200 rows.
SELECT COUNT(*) AS row_count FROM orders;

-- 9.2 Expected 0 duplicate OrderIDs.
SELECT COUNT(*) - COUNT(DISTINCT OrderID) AS duplicate_order_ids FROM orders;

-- 9.3 Expected 0 duplicate TrackingNumbers.
SELECT COUNT(*) - COUNT(DISTINCT TrackingNumber) AS duplicate_tracking_numbers FROM orders;

-- 9.4 Expected 309 missing coupon codes.
SELECT COUNT(*) AS null_coupon_codes FROM orders WHERE CouponCode IS NULL;

-- 9.5 Expected 0 pricing inconsistencies.
SELECT COUNT(*) AS price_mismatches
FROM orders
WHERE ROUND(Quantity * UnitPrice, 2) <> ROUND(TotalPrice, 2);

-- 9.6 Expected total 1,264,761.96 and average 1,053.97.
SELECT ROUND(SUM(TotalPrice), 2) AS total_revenue,
       ROUND(AVG(TotalPrice), 2) AS average_order_value
FROM orders;
