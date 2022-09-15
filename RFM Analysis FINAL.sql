--Inspecting Data
SELECT * FROM dbo.sales_data_sample;

--Checking Unique Values 

SELECT DISTINCT(status) FROM dbo.sales_data_sample; --nice one to plot in Tableau

SELECT DISTINCT(year_id) FROM dbo.sales_data_sample;

SELECT DISTINCT(productline) FROM dbo.sales_data_sample; --nice one to plot in Tableau

SELECT DISTINCT(country) FROM dbo.sales_data_sample; --nice one to plot in Tableau

SELECT DISTINCT(dealsize) FROM dbo.sales_data_sample; --nice one to plot in Tableau

SELECT DISTINCT(territory) FROM dbo.sales_data_sample; --nice one to plot in Tableau


--Analysis
-- Looking at Sales by Productline 

SELECT Productline, SUM(Sales) AS Revenue FROM dbo.sales_data_sample 
GROUP BY Productline
ORDER BY 2 DESC;
--Top 3- Classic Cars, Vintage Cars and Motorcycles

--Looking at Revenue across years

SELECT Year_ID, SUM(Sales) AS Revenue FROM dbo.sales_data_sample 
GROUP BY Year_ID
ORDER BY 2 DESC;

--Figuring out why 2005 has the lowest sales 

SELECT DISTINCT(Month_id) FROM dbo.sales_data_sample
WHERE Year_id = 2005
ORDER BY 1 ASC;
-- Ans:Only operated 5 months in 2005

-- Looking at Sales by Dealsize

SELECT * FROM dbo.sales_data_sample;

SELECT Dealsize, SUM(Sales) AS Revenue FROM dbo.sales_data_sample 
GROUP BY Dealsize
ORDER BY 2 DESC;

--What was the best month for sales in a specific year? How much was earned that month?

SELECT Month_ID, SUM(Sales) AS Revenue, COUNT(Ordernumber) AS Frequency FROM dbo.sales_data_sample 
WHERE Year_ID = 2004
GROUP BY Month_ID
ORDER BY 2 DESC;

SELECT Month_ID, SUM(Sales) AS Revenue, COUNT(Ordernumber) AS Frequency FROM dbo.sales_data_sample 
WHERE Year_ID = 2003
GROUP BY Month_ID
ORDER BY 2 DESC;
-- November and October have the highest sales in both 2003 and 2004 

SELECT Month_ID, SUM(Sales) AS Revenue, COUNT(Ordernumber) AS Frequency FROM dbo.sales_data_sample 
WHERE Year_ID = 2005
GROUP BY Month_ID
ORDER BY 2 DESC;
--Out of five operating months in 2015, May has the highest sales.

--November seems to be the significant month, which products do they sell?
SELECT Month_ID, Productline, SUM(Sales) AS Revenue, COUNT(Ordernumber) AS Frequency FROM dbo.sales_data_sample 
WHERE Year_ID = 2003 AND Month_ID = 11
GROUP BY Month_ID, Productline
ORDER BY 3 DESC;

SELECT Month_ID, Productline, SUM(Sales) AS Revenue, COUNT(Ordernumber) AS Frequency FROM dbo.sales_data_sample 
WHERE Year_ID = 2004 AND Month_ID = 11
GROUP BY Month_ID, Productline
ORDER BY 3 DESC;
--Classic and Vintage Cars are the best selling items in both yearw.


--Who is our best customer? (This could be best answered with RFM)
--recency (how long ago last purchase was)
--frequency (how often do they purchase)
--monetary (how much they spend)

--Creating Temp table
DROP TABLE IF EXISTS #RFM;
WITH RFM AS(
SELECT CustomerName, 
COUNT(OrderNumber) AS Frequency,
SUM(Sales) AS MonetaryValue,
AVG(Sales) AS AvgMonetaryValue,
MAX(OrderDate) AS Last_OrderDate, (SELECT MAX(OrderDate) FROM dbo.sales_data_sample) AS Last_DataDate,
DATEDIFF(Day,MAX(OrderDate), (SELECT MAX(OrderDate) FROM dbo.sales_data_sample)) AS Recency
FROM dbo.sales_data_sample
GROUP BY CustomerName),
RFM_Calc AS (
SELECT RFM.*,
NTILE (4) OVER (ORDER BY Recency DESC) RFM_Recency,
NTILE (4) OVER (ORDER BY Frequency) RFM_Frequency,
NTILE (4) OVER (ORDER BY MonetaryValue) RFM_Monetary
FROM RFM)
SELECT *, (RFM_Recency+RFM_Frequency+RFM_Monetary) AS RFM_cell,
(CAST(RFM_Recency AS VARCHAR)+ CAST (RFM_Frequency AS VARCHAR)+ CAST(RFM_Monetary AS VARCHAR)) AS RFM_cell_string
INTO #RFM
FROM RFM_Calc; 

--CREATING CUSTOMER SEGMENT 
SELECT CustomerName, RFM_Recency, RFM_Frequency, RFM_Monetary,
CASE 
WHEN RFM_cell_string IN (111, 112, 121, 122, 123, 132,211, 212, 221) THEN 'Lost_Customers'
WHEN RFM_cell_string IN (144, 234,244,144,133,343,344) THEN 'Slipping Away,Cant lose'
WHEN RFM_cell_string IN (412,311) THEN 'New_Customers'
WHEN RFM_cell_string IN (222,223,232, 233,322) THEN 'Potential Churners'
WHEN RFM_cell_string IN (422,421,332,333) THEN 'Active'
WHEN RFM_cell_string IN (443,444,433,434) THEN 'Loyal'
END RFM_Segment
FROM #RFM;

--What products are often sold together??

SELECT DISTINCT(OrderNumber), stuff(
(SELECT ',' +ProductCode FROM dbo.sales_data_sample P1
WHERE OrderNumber IN
(SELECT OrderNumber FROM 
(SELECT OrderNumber, COUNT(*) order_count FROM dbo.sales_data_sample
WHERE Status = 'Shipped'
GROUP BY OrderNumber) A1
WHERE order_count = 2) AND P1.OrderNumber = P2.OrderNumber
FOR xml path ('')),1,1,'') ProductCodes FROM dbo.sales_data_sample P2
ORDER BY 2 DESC;