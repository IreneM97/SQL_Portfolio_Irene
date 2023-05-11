

-- DATA CLEANING AND PREPARATION
-- as some columns are showing 1 instead of "True", we are updating those to make the data 
--consistent across all similar columns

ALTER TABLE dbo.EcommerceCustomers
ALTER COLUMN Landing_Page NVARCHAR(255);

ALTER TABLE dbo.EcommerceCustomers
ALTER COLUMN Product_Page NVARCHAR(255);

ALTER TABLE dbo.EcommerceCustomers
ALTER COLUMN Purchase NVARCHAR(255);

ALTER TABLE dbo.EcommerceCustomers
ALTER COLUMN Date DATE;


UPDATE dbo.EcommerceCustomers
SET Landing_Page = CASE WHEN Landing_Page = 1 THEN 'TRUE' ELSE 'FALSE' END;

UPDATE dbo.EcommerceCustomers
SET Product_Page = CASE WHEN Product_Page = 1 THEN 'TRUE'ELSE 'FALSE' END;

UPDATE dbo.EcommerceCustomers
SET Purchase = CASE WHEN Purchase = 1 THEN 'TRUE'ELSE 'FALSE' END;

SELECT * FROM dbo.EcommerceCustomers;

-- total number of customers
SELECT COUNT(DISTINCT customer_id) AS total_customers FROM dbo.EcommerceCustomers;

-- Customer Count and Percentage By Gender
WITH CTE AS (SELECT Gender, COUNT(*) AS number_of_customers
FROM dbo.EcommerceCustomers
GROUP BY Gender)
SELECT *, 100*(CAST (number_of_customers AS float)/
CAST ((SELECT COUNT(*) FROM dbo.EcommerceCustomers)AS float)) AS percentage_of_customers
FROM CTE
ORDER BY percentage_of_customers DESC;


-- Customer visits by year and month
SELECT YEAR(Date) AS Year, MONTH(Date) AS Month, COUNT(customer_id) FROM dbo.EcommerceCustomers
GROUP BY YEAR(Date) , MONTH(Date) ;


-- Product categories customers looked at 
SELECT DISTINCT product_category FROM dbo.EcommerceCustomers
WHERE product_category != 'N/A';


-- Funney Analysis
SELECT * FROM dbo.EcommerceCustomers;

WITH landing_page AS (SELECT customer_id FROM dbo.EcommerceCustomers
WHERE landing_page = 'TRUE'),
product_page AS (SELECT landing_page.customer_id FROM landing_page --to ensure we only look at customers who had been on landing page defined above
JOIN dbo.EcommerceCustomers
ON landing_page.customer_id= dbo.EcommerceCustomers.customer_id
WHERE product_page = 'TRUE'),
add_to_cart AS (SELECT product_page.customer_id FROM product_page --to ensure we only look at customers who had been on product_page defined above
JOIN dbo.EcommerceCustomers
ON product_page.customer_id= dbo.EcommerceCustomers.customer_id
WHERE Add_to_Cart = 'TRUE'),
check_out AS(SELECT Add_to_Cart.customer_id FROM Add_to_Cart --to ensure we only look at customers tried to add items to the cart defined above
JOIN dbo.EcommerceCustomers
ON Add_to_cart.customer_id= dbo.EcommerceCustomers.customer_id
WHERE check_out = 'TRUE'),
purchase AS (SELECT check_out.customer_id FROM check_out --to ensure we only look at customers attempted to check out defined above
JOIN dbo.EcommerceCustomers
ON check_out.customer_id= dbo.EcommerceCustomers.customer_id
WHERE purchase = 'TRUE'),
customers_count_by_phase AS (SELECT 'Landing_page' AS phase, COUNT(*) AS customers_count FROM landing_page
UNION 
SELECT 'Product_page' AS phase, COUNT(*) AS customers_count  FROM product_page
UNION 
SELECT 'Add_to_Cart' AS phase, COUNT(*) AS customers_count FROM Add_to_Cart
UNION 
SELECT 'Check_Out' AS phase, COUNT(*) AS customers_count FROM check_out
UNION 
SELECT 'Purchase' AS phase, COUNT(*) AS customers_count FROM purchase
)
SELECT * INTO #total_customers_by_phase FROM customers_count_by_phase 
ORDER BY customers_count DESC

SELECT * FROM #total_customers_by_phase

-- As the original data is cleaned and organized, we can calculate funnel analysis in shorter form.
-- However, the type of calculation is not recommended especially for unorganized data.

SELECT 
COUNT(CASE WHEN landing_page = 'TRUE'THEN customer_id ELSE NULL END) AS landing_page_customers,
COUNT(CASE WHEN product_page = 'TRUE' THEN customer_id ELSE NULL END) AS product_page_customers,
COUNT(CASE WHEN Add_to_cart = 'TRUE' THEN customer_id ELSE NULL END) AS add_to_cart_customers,
COUNT(CASE WHEN Check_Out = 'TRUE' THEN customer_id ELSE NULL END) AS check_out,
COUNT(CASE WHEN Purchase = 'TRUE' THEN customer_id ELSE NULL END) AS purchase
FROM dbo.EcommerceCustomers;


-- Conversion Rate 
SELECT phase,SUM(customers_count) AS no_of_customers, 100*(CAST (SUM(customers_count)AS float)/CAST((SELECT SUM(customers_count) FROM #total_customers_by_phase WHERE phase= 'landing_page') AS float)) AS conversion_rate
FROM #total_customers_by_phase
GROUP BY phase
ORDER BY conversion_rate DESC;

-- Creating a temp table for ID of customers who made a purchase on the webiste 
WITH landing_page AS (SELECT customer_id FROM dbo.EcommerceCustomers
WHERE landing_page = 'TRUE'),
product_page AS (SELECT landing_page.customer_id FROM landing_page --to ensure we only look at customers who had been on landing page defined above
JOIN dbo.EcommerceCustomers
ON landing_page.customer_id= dbo.EcommerceCustomers.customer_id
WHERE product_page = 'TRUE'),
add_to_cart AS (SELECT product_page.customer_id FROM product_page --to ensure we only look at customers who had been on product_page defined above
JOIN dbo.EcommerceCustomers
ON product_page.customer_id= dbo.EcommerceCustomers.customer_id
WHERE Add_to_Cart = 'TRUE'),
check_out AS(SELECT Add_to_Cart.customer_id FROM Add_to_Cart --to ensure we only look at customers tried to add items to the cart defined above
JOIN dbo.EcommerceCustomers
ON Add_to_cart.customer_id= dbo.EcommerceCustomers.customer_id
WHERE check_out = 'TRUE'),
purchase AS (SELECT check_out.customer_id FROM check_out --to ensure we only look at customers attempted to check out defined above
JOIN dbo.EcommerceCustomers
ON check_out.customer_id= dbo.EcommerceCustomers.customer_id
WHERE purchase = 'TRUE')
SELECT * INTO #IDs_Purchase_customers
FROM purchase

SELECT * FROM #IDs_Purchase_customers;


-- Which category did the converted customers purchase the most?
SELECT Product_Category, COUNT(#IDs_Purchase_customers.customer_id) AS customers FROM #IDs_Purchase_customers
JOIN dbo.EcommerceCustomers
ON #IDs_Purchase_customers.customer_id= dbo.EcommerceCustomers.customer_id
--WHERE YEAR(DATE)= 2022
GROUP BY product_category
ORDER BY customers DESC
--For 2022 top product categories are alumnium foil, vacccum sealer bags,ziplock bags
-- For 2023 top product categories are plastic wrap,vaccum sealer bags, alumnium foil


-- For the customers who did not proceed to "add to cart" phase from "product page", which product category were they looking at?

WITH landing_page AS (SELECT customer_id FROM dbo.EcommerceCustomers
WHERE landing_page = 'TRUE'),
product_page AS (SELECT landing_page.customer_id FROM landing_page --to ensure we only look at customers who had been on landing page defined above
JOIN dbo.EcommerceCustomers
ON landing_page.customer_id= dbo.EcommerceCustomers.customer_id
WHERE product_page = 'TRUE'),
dropped_out AS (SELECT product_page.customer_id, Product_Category FROM product_page --to ensure we only look at customers who had been on product_page defined above
JOIN dbo.EcommerceCustomers
ON product_page.customer_id = dbo.EcommerceCustomers.customer_id
WHERE Add_to_Cart = 'FALSE')
SELECT Product_Category, COUNT(customer_id) AS customers_count FROM dropped_out  
GROUP BY Product_Category
ORDER BY customers_count DESC;
-- customers were looking at wax paper and tin foil.


-- For the customers who did not proceed to "check-out" phase from "add-to-cart", which product category were they looking at?

WITH landing_page AS (SELECT customer_id FROM dbo.EcommerceCustomers
WHERE landing_page = 'TRUE'),
product_page AS (SELECT landing_page.customer_id FROM landing_page --to ensure we only look at customers who had been on landing page defined above
JOIN dbo.EcommerceCustomers
ON landing_page.customer_id= dbo.EcommerceCustomers.customer_id
WHERE product_page = 'TRUE'),
add_to_cart AS (SELECT product_page.customer_id FROM product_page --to ensure we only look at customers who had been on product_page defined above
JOIN dbo.EcommerceCustomers
ON product_page.customer_id= dbo.EcommerceCustomers.customer_id
WHERE Add_to_Cart = 'TRUE'),
check_out AS(SELECT Add_to_Cart.customer_id, Product_Category FROM Add_to_Cart --to ensure we only look at customers tried to add items to the cart defined above
JOIN dbo.EcommerceCustomers
ON Add_to_cart.customer_id= dbo.EcommerceCustomers.customer_id
WHERE check_out = 'FALSE')
SELECT Product_Category, COUNT(customer_id) AS customers_count FROM check_out
GROUP BY Product_Category
ORDER BY customers_count DESC;
-- top products customers were looking at are food storage containers, plastic wraps and reseaable bags
