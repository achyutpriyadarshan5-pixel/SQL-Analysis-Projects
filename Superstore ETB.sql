-- DMART SQL Analytics (simple version, MySQL 8)
-- Table: superstore_orders_mysql_ascii

   USE ETB;


-- Q1. Top 10 sub-categories by sales, and their profit rank ----------
SELECT * FROM (
    SELECT `Product Sub-Category`,
           SUM(`Sales`)  AS total_sales,
           SUM(`Profit`) AS total_profit,
           RANK() OVER (ORDER BY SUM(`Sales`)DESC) AS sales_rank,
           RANK() OVER (ORDER BY SUM(`Profit`)DESC) AS profit_rank
    FROM superstore_orders_mysql_ascii
    GROUP BY `Product Sub-Category`
) t
WHERE sales_rank <= 10
ORDER BY sales_rank;

-- Q2. High sales but negative profit (products) ----------------------
SELECT `Product Name`, SUM(`Sales`) AS total_sales, SUM(`Profit`) AS total_profit
FROM superstore_orders_mysql_ascii
GROUP BY `Product Name`
HAVING SUM(`Profit`) < 0 AND SUM(`Sales`) > 5000      -- change 5000 to your "high `Sales`" cut-off
ORDER BY total_sales DESC;
 
 
-- Q3. Category with highest avg discount and lowest avg profit -------
SELECT `Product Category`,
       AVG(`Discount`) AS avg_discount,
       AVG(`Profit`)   AS avg_profit
FROM superstore_orders_mysql_ascii
GROUP BY `Product Category`
ORDER BY avg_discount DESC;
-- Compare: top row = highest discount; smallest avg_profit = lowest profit.
 
 
-- Q4. Sub-categories: sales above average, profit below average ------
SELECT `Product Sub-Category`, SUM(`Sales`) AS total_sales, SUM(`Profit`) AS total_profit
FROM superstore_orders_mysql_ascii
GROUP BY `Product Sub-Category`
HAVING SUM(`Sales`)  > (SELECT AVG(s) FROM (SELECT SUM(`Sales`)  AS s FROM superstore_orders_mysql_ascii GROUP BY `Product Sub-Category`) a)
   AND SUM(`Profit`) < (SELECT AVG(p) FROM (SELECT SUM(`Profit`) AS p FROM superstore_orders_mysql_ascii GROUP BY `Product Sub-Category`) b);
 
 
-- Q5. Segment: highest sales, lowest profit margin -------------------
SELECT `Customer Segment`,
       SUM(`Sales`)  AS total_sales,
       SUM(`Profit`) AS total_profit,
       SUM(`Profit`) / SUM(`Sales`) * 100 AS profit_margin_pct
FROM superstore_orders_mysql_ascii
GROUP BY `Customer Segment`
ORDER BY total_sales DESC;
 
 
-- Q6. Top category by sales in each region ---------------------------
SELECT `Region`, `Product Category`, total_sales FROM (
    SELECT `Region`, `Product Category`, SUM(`Sales`) AS total_sales,
           RANK() OVER (PARTITION BY `Region` ORDER BY SUM(`Sales`) DESC) AS rnk
    FROM superstore_orders_mysql_ascii
    GROUP BY `Region`, `Product Category`
) t
WHERE rnk = 1;
 
 
-- Q7. Top 3 customers in each region ---------------------------------
SELECT `Region`, `Customer Name`, total_sales FROM (
    SELECT `Region`, `Customer Name`, SUM(`Sales`) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY `Region` ORDER BY SUM(`Sales`) DESC) AS rn
    FROM superstore_orders_mysql_ascii
    GROUP BY `Region`, `Customer Name`
) t
WHERE rn <= 3
ORDER BY `Region`, total_sales DESC;
 
 
-- Q8. Customers with high sales but negative profit ------------------
SELECT `Customer Name`, SUM(`Sales`) AS total_sales, SUM(`Profit`) AS total_profit
FROM superstore_orders_mysql_ascii
GROUP BY `Customer Name`
HAVING SUM(`Profit`) < 0 AND SUM(`Sales`) > 5000      -- change 5000 to your "high `Sales`" cut-off
ORDER BY total_sales DESC;
 
 
-- Q9. Discount range vs average profit -------------------------------
SELECT CASE
           WHEN `Discount` = 0    THEN '1. No discount'
           WHEN `Discount` <= 0.03 THEN '2. Low (up to 3%)'
           WHEN `Discount` <= 0.06 THEN '3. Medium (3-6%)'
           ELSE                       '4. High (above 6%)'
       END AS discount_range,
       COUNT(*)    AS transactions,
       AVG(`Profit`) AS avg_profit
FROM superstore_orders_mysql_ascii
GROUP BY discount_range
ORDER BY discount_range;
 
 
-- Q10. Shipping cost relative to sales, by sub-category --------------
SELECT `Product Sub-Category`,
       SUM(`Shipping Cost`) / SUM(`Sales`) * 100 AS shipping_pct_of_sales
FROM superstore_orders_mysql_ascii
GROUP BY `Product Sub-Category`
ORDER BY shipping_pct_of_sales DESC;
 
 
-- Q11. Category-Region: highest sales, lowest margin -----------------
SELECT `Product Category`, `Region`,
       SUM(`Sales`) AS total_sales,
       SUM(`Profit`) / SUM(`Sales`) * 100 AS profit_margin_pct
FROM superstore_orders_mysql_ascii
GROUP BY `Product Category`, `Region`
ORDER BY total_sales DESC, profit_margin_pct ASC;
 
 
-- Q12. Products: sales above average, profit below average -----------
SELECT `Product Name`, SUM(`Sales`) AS total_sales, SUM(`Profit`) AS total_profit
FROM superstore_orders_mysql_ascii
GROUP BY `Product Name`
HAVING SUM(`Sales`)  > (SELECT AVG(s) FROM (SELECT SUM(`Sales`)  AS s FROM superstore_orders_mysql_ascii GROUP BY `Product Name`) a)
   AND SUM(`Profit`) < (SELECT AVG(p) FROM (SELECT SUM(`Profit`) AS p FROM superstore_orders_mysql_ascii GROUP BY `Product Name`) b)
ORDER BY total_sales DESC;
 
 
-- Q13. Year-over-year sales growth -----------------------------------
SELECT YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y')) AS yr,
       SUM(`Sales`) AS total_sales,
       LAG(SUM(`Sales`)) OVER (ORDER BY YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS prev_year_sales,
       (SUM(`Sales`) - LAG(SUM(`Sales`)) OVER (ORDER BY YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))))
           / LAG(SUM(`Sales`)) OVER (ORDER BY YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) * 100 AS yoy_growth_pct
FROM superstore_orders_mysql_ascii
GROUP BY YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))
ORDER BY yr;

 
 
-- Q14. Customers who bought from more than one category --------------
SELECT `Customer Name`, COUNT(DISTINCT `Product Category`) AS categories
FROM superstore_orders_mysql_ascii
GROUP BY `Customer Name`
HAVING COUNT(DISTINCT `Product Category`) > 1
ORDER BY categories DESC;
 
 
-- Q15. Customers with sales above average customer sales, ranked -----
SELECT `Customer Name`,
       SUM(`Sales`) AS total_sales,
       RANK() OVER (ORDER BY SUM(`Sales`) DESC) AS sales_rank
FROM superstore_orders_mysql_ascii
GROUP BY `Customer Name`
HAVING SUM(`Sales`) > (SELECT AVG(s) FROM (SELECT SUM(`Sales`) AS s FROM superstore_orders_mysql_ascii GROUP BY `Customer Name`) t)
ORDER BY sales_rank;
 
 
-- Q16. Top sub-category share within each category -------------------
SELECT `Product Category`, `Product Sub-Category`, pct_of_category FROM (
    SELECT `Product Category`, `Product Sub-Category`,
           SUM(`Sales`) / SUM(SUM(`Sales`)) OVER (PARTITION BY `Product Category`) * 100 AS pct_of_category,
           RANK() OVER (PARTITION BY `Product Category` ORDER BY SUM(`Sales`) DESC) AS rnk
    FROM superstore_orders_mysql_ascii
    GROUP BY `Product Category`, `Product Sub-Category`
) t
WHERE rnk = 1;
 
 
-- Q17. Sub-categories with sales up but profit down (year over year) -
SELECT * FROM (
    SELECT `Product Sub-Category`,
           YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y')) AS yr,
           SUM(`Sales`)  AS total_sales,
           SUM(`Profit`) AS total_profit,
           LAG(SUM(`Sales`))  OVER (PARTITION BY `Product Sub-Category` ORDER BY YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS prev_sales,
           LAG(SUM(`Profit`)) OVER (PARTITION BY `Product Sub-Category` ORDER BY YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS prev_profit
    FROM superstore_orders_mysql_ascii
    GROUP BY `Product Sub-Category`, YEAR(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))
) t
WHERE total_sales > prev_sales AND total_profit < prev_profit
ORDER BY `Product Sub-Category`, yr;
 
 
-- Q18. Top 5 products by sales in each customer segment --------------
SELECT `Customer Segment`, `Product Name`, total_sales FROM (
    SELECT `Customer Segment`, `Product Name`, SUM(`Sales`) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY `Customer Segment` ORDER BY SUM(`Sales`) DESC) AS rn
    FROM superstore_orders_mysql_ascii
    GROUP BY `Customer Segment`, `Product Name`
) t
WHERE rn <= 5
ORDER BY `Customer Segment`, total_sales DESC;
 
 
-- Q19. Average shipping days by ship mode ----------------------------
SELECT `Ship Mode`, AVG(DATEDIFF(STR_TO_DATE(`Ship Date`, '%m/%d/%Y'), STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS avg_shipping_days
FROM superstore_orders_mysql_ascii
GROUP BY `Ship Mode`
ORDER BY avg_shipping_days DESC;
 
 
-- Q20. Orders where shipping cost is greater than profit -------------
SELECT `Order ID`, SUM(`Shipping Cost`) AS total_shipping_cost, SUM(`Profit`) AS total_profit
FROM superstore_orders_mysql_ascii
GROUP BY `Order ID`
HAVING SUM(`Shipping Cost`) > SUM(`Profit`);
 
-- Count of such orders
SELECT COUNT(*) AS num_orders FROM (
    SELECT `Order ID`
    FROM superstore_orders_mysql_ascii
    GROUP BY `Order ID`
    HAVING SUM(`Shipping Cost`) > SUM(`Profit`)
) t;

-- END OF THE QUESTUONS AND QUERY -------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------