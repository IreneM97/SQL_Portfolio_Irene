--Exploring Data
-- Total Raw Records = 541909
-- 135080 records have no customerid
-- 406829 records have valid customerid
-- Transactions with null price and quantity are filtered
-- 397,884 records final

--Cleaning Data
WITH CTE AS (SELECT * FROM dbo.OnlineRetail
WHERE customerid != 0 AND UnitPrice > 0 AND  Quantity > 0),
--Checking Duplicates
DuplicatesCheck AS (SELECT *,ROW_NUMBER() OVER (PARTITION BY invoiceno,stockcode,quantity ORDER BY invoicedate) AS dup_row
FROM CTE)
--Extracting Unique Values (392669 rows of unique data)
SELECT * into #OnlineRetail
FROM DuplicatesCheck
WHERE dup_row = 1;

-- 1. Cohort Analysis - User Retention 

-- Step 1 : finding first purchase date and its turncated month of each customers 

WITH cohort AS (SELECT customerid, MIN(InvoiceDate) as first_purchase_date, 
DATEFROMPARTS (YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) AS cohort_date --turncating date to month
FROM #OnlineRetail
GROUP BY customerid)

-- Step 3 : calculating cohort_index with time_interval and creating cohort retention table

SELECT *, (yeardiff *12 + monthdiff + 1) AS cohortindex --formula 
into #cohort_retention

FROM 

-- Step 2 : calculating interval between invoice date and cohort_date
(SELECT *, (invoiceyear - cohortyear) as yeardiff, (invoicemonth - cohortmonth) as monthdiff FROM 
(SELECT A.*, YEAR(InvoiceDate) AS invoiceyear, MONTH(InvoiceDate) AS invoicemonth, cohort_date,
YEAR(cohort_date) AS cohortyear, MONTH(cohort_date) AS cohortmonth
FROM #OnlineRetail AS A
LEFT JOIN cohort
ON A.customerid = cohort.customerid) AS time_interval) AS cohort_index
--WHERE customerID = 14733;

--Cohort index indicates the month lapse between that specific transaction and the first transaction that user made on the website.
-- Index 1 means this customer makes their next purchase on the same month they made their 1st purchase 

SELECT * FROM #cohort_retention;

-- Grouping total customers by cohort index and checking how many % of customers return in each cohort month

SELECT cohort_date,
COUNT(CASE WHEN cohortindex = 1 THEN customerid ELSE NULL END) AS CI1,
COUNT(CASE WHEN cohortindex = 2 THEN customerid ELSE NULL END) AS CI2,
COUNT(CASE WHEN cohortindex = 3 THEN customerid ELSE NULL END) AS CI3,
COUNT(CASE WHEN cohortindex = 4 THEN customerid ELSE NULL END) AS CI4,
COUNT(CASE WHEN cohortindex = 5 THEN customerid ELSE NULL END) AS CI5,
COUNT(CASE WHEN cohortindex = 6 THEN customerid ELSE NULL END) AS CI6,
COUNT(CASE WHEN cohortindex = 7 THEN customerid ELSE NULL END) AS CI7,
COUNT(CASE WHEN cohortindex = 8 THEN customerid ELSE NULL END) AS CI8,
COUNT(CASE WHEN cohortindex = 9 THEN customerid ELSE NULL END) AS CI9,
COUNT(CASE WHEN cohortindex = 10 THEN customerid ELSE NULL END) AS CI10,
COUNT(CASE WHEN cohortindex = 11 THEN customerid ELSE NULL END) AS CI11,
COUNT(CASE WHEN cohortindex = 12 THEN customerid ELSE NULL END) AS CI12,
COUNT(CASE WHEN cohortindex = 13 THEN customerid ELSE NULL END) AS CI13
into #CIpivot
FROM 
(SELECT DISTINCT customerid, cohort_date, cohortindex
FROM #cohort_retention) AS CR
GROUP BY cohort_date
ORDER BY cohort_date;

SELECT cohort_date, ROUND(CAST(CI1 AS float)/(CI1)*100,2) AS CI1,
ROUND(CAST(CI2 AS float)/(CI1)*100,2) AS CI2,
ROUND(CAST(CI3 AS float)/(CI1)*100,2) AS CI3,
ROUND(CAST(CI4 AS float)/(CI1)*100,2) AS CI4,
ROUND(CAST(CI5 AS float)/(CI1)*100,2) AS CI5,
ROUND(CAST(CI6 AS float)/(CI1)*100,2) AS CI6,
ROUND(CAST(CI7 AS float)/(CI1)*100,2) AS CI7,
ROUND(CAST(CI8 AS float)/(CI1)*100,2) AS CI8,
ROUND(CAST(CI9 AS float)/(CI1)*100,2) AS CI9,
ROUND(CAST(CI10 AS float)/(CI1)*100,2) AS CI10,
ROUND(CAST(CI11 AS float)/(CI1)*100,2) AS CI11,
ROUND(CAST(CI12 AS float)/(CI1)*100,2) AS CI12,
ROUND(CAST(CI13 AS float)/(CI1)*100,2) AS CI13
FROM #CIpivot
ORDER BY cohort_date

-- 38.42% of Customers who made 1st purchase in December 2010 came back 4 months after their 1st purchase month.

-- 2. Cohort Analysis - Average Quantity Sold

SELECT cohort_date,  
ROUND(AVG(CASE WHEN cohortindex = 1 THEN quantity ELSE NULL END),2) AS CI1,
ROUND(AVG(CASE WHEN cohortindex = 2 THEN quantity ELSE NULL END),2) AS CI2,
ROUND(AVG(CASE WHEN cohortindex = 3 THEN quantity ELSE NULL END),2) AS CI3,
ROUND(AVG(CASE WHEN cohortindex = 4 THEN quantity ELSE NULL END),2) AS CI4,
ROUND(AVG(CASE WHEN cohortindex = 5 THEN quantity ELSE NULL END),2) AS CI5,
ROUND(AVG(CASE WHEN cohortindex = 6 THEN quantity ELSE NULL END),2) AS CI6,
ROUND(AVG(CASE WHEN cohortindex = 7 THEN quantity ELSE NULL END),2) AS CI7,
ROUND(AVG(CASE WHEN cohortindex = 8 THEN quantity ELSE NULL END),2) AS CI8,
ROUND(AVG(CASE WHEN cohortindex = 9 THEN quantity ELSE NULL END),2) AS CI9,
ROUND(AVG(CASE WHEN cohortindex = 10 THEN quantity ELSE NULL END),2) AS CI10,
ROUND(AVG(CASE WHEN cohortindex = 11 THEN quantity ELSE NULL END),2) AS CI11,
ROUND(AVG(CASE WHEN cohortindex = 12 THEN quantity ELSE NULL END),2) AS CI12,
ROUND(AVG(CASE WHEN cohortindex = 13 THEN quantity ELSE NULL END),2) AS CI13
INTO #cohort_avg_quantity_sold
FROM #cohort_retention
GROUP BY cohort_date
ORDER BY cohort_date;

SELECT * FROM #cohort_avg_quantity_sold
ORDER BY cohort_date;



-- 3. Cohort Analysis - Average Sales 
SELECT cohort_date,  
ROUND(AVG(CASE WHEN cohortindex = 1 THEN sales ELSE NULL END),2) AS CI1,
ROUND(AVG(CASE WHEN cohortindex = 2 THEN sales ELSE NULL END),2) AS CI2,
ROUND(AVG(CASE WHEN cohortindex = 3 THEN sales ELSE NULL END),2) AS CI3,
ROUND(AVG(CASE WHEN cohortindex = 4 THEN sales ELSE NULL END),2) AS CI4,
ROUND(AVG(CASE WHEN cohortindex = 5 THEN sales ELSE NULL END),2) AS CI5,
ROUND(AVG(CASE WHEN cohortindex = 6 THEN sales ELSE NULL END),2) AS CI6,
ROUND(AVG(CASE WHEN cohortindex = 7 THEN sales ELSE NULL END),2) AS CI7,
ROUND(AVG(CASE WHEN cohortindex = 8 THEN sales ELSE NULL END),2) AS CI8,
ROUND(AVG(CASE WHEN cohortindex = 9 THEN sales ELSE NULL END),2) AS CI9,
ROUND(AVG(CASE WHEN cohortindex = 10 THEN sales ELSE NULL END),2) AS CI10,
ROUND(AVG(CASE WHEN cohortindex = 11 THEN sales ELSE NULL END),2) AS CI11,
ROUND(AVG(CASE WHEN cohortindex = 12 THEN sales ELSE NULL END),2) AS CI12,
ROUND(AVG(CASE WHEN cohortindex = 13 THEN sales ELSE NULL END),2) AS CI13
FROM 
(SELECT *, (UnitPrice * Quantity) AS sales FROM #cohort_retention) AS C
GROUP BY cohort_date
ORDER BY cohort_date;






