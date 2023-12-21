-- 1) Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

SELECT DISTINCT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region IN ('APAC');

-- 2) What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

SELECT 
    COUNT(DISTINCT CASE WHEN fm.fiscal_year = 2020 THEN fp.product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fm.fiscal_year = 2021 THEN fp.product_code END) AS unique_products_2021,
    ROUND((COUNT(DISTINCT CASE WHEN fm.fiscal_year = 2021 THEN fp.product_code END) - 
           COUNT(DISTINCT CASE WHEN fm.fiscal_year = 2020 THEN fp.product_code END)) /
          COUNT(DISTINCT CASE WHEN fm.fiscal_year = 2020 THEN fp.product_code END) * 100, 2) AS percentage_chg
FROM fact_sales_monthly fm
JOIN fact_gross_price fp ON fm.product_code = fp.product_code
WHERE fm.fiscal_year IN (2020, 2021);

-- 3) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count

SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4) Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference
SELECT 
    dp.segment,
    COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2020 THEN fsm.product_code END) AS product_count_2020,
    COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2021 THEN fsm.product_code END) AS product_count_2021,
    (COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2021 THEN fsm.product_code END) - 
     COUNT(DISTINCT CASE WHEN fsm.fiscal_year = 2020 THEN fsm.product_code END)) AS difference
FROM fact_sales_monthly fsm
JOIN dim_product dp ON fsm.product_code = dp.product_code
WHERE fsm.fiscal_year IN (2020, 2021)
GROUP BY dp.segment
ORDER BY difference DESC
LIMIT 1;

-- 5) Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost
-- To get the product with the highest manufacturing cost:
SELECT 
    fm.product_code, 
    dp.product,
    fm.manufacturing_cost
FROM fact_manufacturing_cost fm
JOIN dim_product dp ON fm.product_code = dp.product_code
ORDER BY fm.manufacturing_cost DESC
LIMIT 1;
-- To get the product with the lowest manufacturing cost:
SELECT 
    fm.product_code, 
    dp.product,
    fm.manufacturing_cost
FROM fact_manufacturing_cost fm
JOIN dim_product dp ON fm.product_code = dp.product_code
ORDER BY fm.manufacturing_cost ASC
LIMIT 1;

-- 6) Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields, customer_code customer average_discount_percentage

SELECT 
    fid.customer_code,
    dc.customer,
    ROUND(AVG(fid.pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM fact_pre_invoice_deductions fid
JOIN dim_customer dc ON fid.customer_code = dc.customer_code
WHERE fid.fiscal_year = 2021
    AND dc.market = 'Indian'
GROUP BY fid.customer_code, dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- 7) Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: Month Year Gross sales Amount

SELECT 
    MONTH(date) AS Month,
    YEAR(date) AS Year,
    SUM(sold_quantity * gross_price) AS Gross_Sales_Amount
FROM fact_sales_monthly
JOIN fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
JOIN dim_customer ON fact_sales_monthly.customer_code = dim_customer.customer_code
WHERE dim_customer.customer = 'Atliq Exclusive'
GROUP BY MONTH(date), YEAR(date)
ORDER BY Year, Month;

-- 8) In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

SELECT 
    QUARTER(date) AS Quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE YEAR(date) = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC
LIMIT 1;

-- 9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage

SELECT 
    dc.channel,
    ROUND(SUM(fp.gross_price) / 1000000, 2) AS gross_sales_mln,
    ROUND(SUM(fp.gross_price) / total_sales * 100, 2) AS percentage
FROM fact_sales_monthly fm
JOIN fact_gross_price fp ON fm.product_code = fp.product_code
JOIN dim_customer dc ON fm.customer_code = dc.customer_code
JOIN (
    SELECT SUM(gross_price) AS total_sales
    FROM fact_gross_price
    WHERE fiscal_year = 2021
) AS total ON 1=1
WHERE fp.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales_mln DESC
LIMIT 1;

-- 10) Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, division product_code product total_sold_quantity rank_order

SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM (
    SELECT 
        dp.division,
        fm.product_code,
        dp.product,
        SUM(fm.sold_quantity) AS total_sold_quantity,
        ROW_NUMBER() OVER (PARTITION BY dp.division ORDER BY SUM(fm.sold_quantity) DESC) AS rank_order
    FROM fact_sales_monthly fm
    JOIN dim_product dp ON fm.product_code = dp.product_code
    WHERE fm.fiscal_year = 2021
    GROUP BY dp.division, fm.product_code, dp.product
) AS RankedProducts
WHERE rank_order <= 3
ORDER BY division, rank_order;

