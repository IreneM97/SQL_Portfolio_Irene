
--Inspecting data
SELECT * FROM dbo.train;

--Checking unique values

SELECT DISTINCT(Ship_Mode) FROM dbo.train;

SELECT DISTINCT(Segment) FROM dbo.train; --customer segment

SELECT DISTINCT(State) FROM dbo.train;

SELECT DISTINCT(Category) FROM dbo.train;

SELECT DISTINCT(Sub_Category) FROM dbo.train;

SELECT DISTINCT (Year(Order_date)) FROM dbo.train; (2015,2016,2017,2018)

--Analysis
-- Looking at sales by each year and which year has highest sales

SELECT Year(Order_date) AS Year, SUM(Sales) AS Total_Sales FROM dbo.train
GROUP BY Year(Order_date)
ORDER BY 2 DESC;
-- 2018 has the highest sales


--What was the best month for sales in a specific year? How much was earned that month?

SELECT Month(Order_Date) AS Month, SUM (Sales) AS Total_Sales, COUNT(ORDER_ID) AS Frequency FROM dbo.train
WHERE Year(Order_date)= 2017 --year can be changed 
GROUP BY Month(Order_Date) 
ORDER BY 2 DESC;
--2018,2016 (November)
--2017(December)
--2015(September)
--Months in Q4 make the highest sales every year

-- Looking at number of subcategory under each product category
SELECT Category, COUNT(Sub_Category) AS Number_of_Sub_Items FROM dbo.train
GROUP BY Category
ORDER BY 2 DESC;
-- Office Supplies has the most items and Technology the least

--Looking at Sales by Product Category across all years
SELECT Category, SUM(Sales) AS Total_Sales FROM dbo.train
GROUP BY Category
ORDER BY Total_Sales DESC;
--Technology category is the best selling one despite having the least subcategory items

-- Looking at customers from which region purchase the most
SELECT State, SUM(Sales) AS Total_Sales FROM dbo.train
GROUP BY State
ORDER BY Total_Sales DESC;


--Who is our best customer? (Answering with RFM method)
--recency (how long ago last purchase was)
--frequency (how often do they purchase)
--monetary (how much they spend)

SELECT * FROM dbo.train;

DROP TABLE IF EXISTS #RFM;
WITH CTE AS
(SELECT Customer_Name, MAX(Order_Date) AS Last_Order_Date, (SELECT MAX(Order_Date) FROM dbo.train) AS Last_Data_Date,
COUNT(Order_ID) AS Frequency, SUM(Sales) AS Monetary,  DATEDIFF(Day,MAX(Order_Date),(SELECT MAX(Order_Date) FROM dbo.train)) AS Datedifference
FROM dbo.train
GROUP BY Customer_Name),
RFM_Calculation AS(
SELECT *, 
NTILE (4) OVER (ORDER BY Datedifference DESC) AS RFM_Recency,
NTILE (4) OVER (ORDER BY Frequency) AS RFM_Frequency,
NTILE (4) OVER (ORDER BY Monetary) AS RFM_Monetary
FROM CTE)
SELECT *,CAST (RFM_Recency AS VARCHAR)+ CAST (RFM_Frequency AS VARCHAR)+ CAST (RFM_Monetary AS VARCHAR) AS RFM_Cell_String 
INTO #RFM
FROM RFM_Calculation;


--Creating Customer Segments
SELECT * FROM #RFM
ORDER BY RFM_Cell_String DESC;

-- lost customers
-- potential churners
-- new customers
-- big purchase customers slipping alway
-- loyal customers
-- active customers (who purchase recently and frequently but lower price point)

SELECT Customer_Name, RFM_Cell_String,
CASE WHEN RFM_Cell_String IN (444,443,434,433) THEN 'Loyal Customers'
WHEN RFM_Cell_String IN (442,432,431,421,422,342,332,331,333) THEN 'Active Customers'
WHEN RFM_Cell_String IN (424,423,414, 413,412,411,314,313,311) THEN 'New Customers'
WHEN RFM_Cell_String IN (133,134,124,143,144,223,224,243,244,334,323,234, 324, 343,344) THEN 'Big Purchasers Slipping Away/Cant lose '
WHEN RFM_Cell_String IN (214,213,222,231,232,233,322,321,312,241,242) THEN 'Potential Churners'
WHEN RFM_Cell_String IN (111,112,113,121,122,123, 131, 132,141,142,211,212,221) THEN 'Lost Customers'
ELSE NULL END AS Customer_Segment 
FROM #RFM;

--What products are often sold together??

WITH CTE1 AS
(SELECT A.Order_ID, Product_ID FROM (
SELECT Order_ID, COUNT(*) AS Order_Count FROM dbo.train
GROUP BY Order_ID
HAVING COUNT(*) = 2) AS A
LEFT JOIN (SELECT Order_ID, Product_ID FROM dbo.train) AS B
ON A.Order_ID = B.Order_ID),
CTE2 AS (SELECT C.Order_ID AS ORDER_ID, C.Product_ID AS P_Code1, D.Product_ID AS P_Code2, ROW_NUMBER () OVER (PARTITION BY C.ORDER_ID ORDER BY C.ORDER_ID) AS Row_Number 
FROM CTE1 AS C
JOIN CTE1 AS D
ON C.Order_ID = D.Order_ID
WHERE C.Product_ID != D.Product_ID)
SELECT ORDER_ID,P_Code1, P_Code2 FROM CTE2
WHERE Row_Number != 1;
