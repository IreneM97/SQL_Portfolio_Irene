
--Raw Data Link 
--https://tinyurl.com/ysmejaxj

-- Inspecting Data 
SELECT * FROM superstoresales;

--Checking unique values

SELECT DISTINCT(Ship_Mode) FROM superstoresales;  
--4 unique modes

SELECT DISTINCT(Segment) FROM superstoresales; 
--Corporate, Home Office and Consumers

SELECT DISTINCT(Region) FROM superstoresales; 
-- 4

SELECT DISTINCT(Category) FROM superstoresales; 
--3

SELECT DISTINCT(Sub_Category) FROM superstoresales; 
-- 17

SELECT DISTINCT(YEAR(Order_Date)) AS years FROM superstoresales; 
--2014, 2015, 2016, 2017


--Which region generated the highest sales 

SELECT Region, SUM(Sales) AS Total_Sales FROM  superstoresales
GROUP BY Region
ORDER BY Total_Sales DESC;

-- Which year has the highest sales 
SELECT YEAR(Order_Date) AS Year, SUM(Sales) AS Total_Sales FROM superstoresales
GROUP BY YEAR(Order_Date)
ORDER BY Total_Sales DESC;

--What was the best month for sales in a specific year? How much was earned that month?

SELECT Year,Month,total_sales FROM 
(SELECT *, ROW_NUMBER() OVER (PARTITION BY Year ORDER BY total_sales DESC) as rn FROM (
SELECT YEAR(Order_Date) AS Year, MONTH(Order_Date) AS Month , SUM(Sales) AS total_sales FROM superstoresales
GROUP BY YEAR(Order_Date),MONTH(Order_Date)) AS A) AS B
WHERE rn =1;
-- Months in Quarter 4 makes the highest sales 


--Which Product Category has the highest profit
SELECT Category, SUM(Profit) AS Total_Profit FROM superstoresales
GROUP BY Category
ORDER BY Total_Profit DESC;
--Technology is the highest profiting category.

--Which Ship_Mode is the most used one?
SELECT Ship_Mode, COUNT(*) AS total_orders FROM superstoresales
GROUP BY Ship_Mode
ORDER BY total_orders DESC;
--Standard Class is the most used ship mode, followed by second class.

--Looking at number of sub-category under each category 
SELECT Category, COUNT(Sub_Category) as No_of_Category FROM superstoresales
GROUP BY Category
--Office Supplies has the highest and Techonogy the lowest in number of sub-category


--Start of RFM analysis
--Creating RFM index

DROP TABLE IF EXISTS #RFM

WITH CTE AS (SELECT Customer_Id, Region, MAX(Order_Date) as Last_Order_Date, COUNT(Order_ID) AS Frequency, 
AVG(Sales) AS Monetary, (SELECT MAX(Order_Date) FROM superstoresales) AS Report_End_Date,
DATEDIFF(Day,MAX(Order_Date),(SELECT MAX(Order_Date) FROM superstoresales)) AS Date_difference FROM superstoresales
GROUP BY Customer_ID,Region),
RFM_Calculation AS(
SELECT *,
NTILE(4) OVER(ORDER BY Date_difference DESC) AS RFM_Recency,
NTILE(4) OVER(ORDER BY Frequency) AS RFM_Frequency,
NTILE(4) OVER(ORDER BY Monetary) AS RFM_Monetary FROM CTE)
SELECT *, CAST(RFM_Recency AS VARCHAR) + CAST(RFM_Frequency AS VARCHAR) + CAST(RFM_Monetary AS VARCHAR) AS RFM_Index
INTO #RFM
FROM RFM_Calculation;

-- Customer Segmentation Based on Index 
SELECT *, 
CASE WHEN RFM_Index IN (444,443,434,433,344,343,333,334) THEN 'Champions'
WHEN RFM_Index IN (442,441,432,431,342,332,331,341) THEN 'Active_Customers'
WHEN RFM_Index IN (424,423,414,413,324,323,313,314) THEN 'Potential Loyalists'
WHEN RFM_Index IN (422,421,412,411,322,321,312,311) THEN 'New Customers'
WHEN RFM_Index IN (242,241,232,231,141,142,131,132,213,214) THEN 'At_Risk'
WHEN RFM_Index IN (234,233,244,243,224,223,234,233,134,133,144,143,124,123,134,133) THEN 'Cant lose'
WHEN RFM_Index IN (212,211,222,221,114,113) THEN 'Hibernating Customers'
WHEN RFM_Index IN (111,121,112,122) THEN 'Lost Customers'
ELSE NULL END AS Customer_Segmentation
INTO #RFM_FINAL
FROM #RFM
ORDER BY RFM_Index DESC;

SELECT * FROM #RFM_FINAL;

-- Customer_Segmentation VS Region

SELECT #RFM_FINAL.Customer_Segmentation, Region, COUNT(customer_id) AS customers, 
100*(COUNT(customer_id)/CAST (A.total_customers AS Float))AS customer_percent
INTO #RFM_Region
FROM #RFM_FINAL
LEFT JOIN (SELECT Customer_Segmentation as CS, COUNT(customer_id) AS total_customers FROM #RFM_FINAL GROUP BY Customer_Segmentation) AS A 
ON #RFM_FINAL.Customer_Segmentation = A.CS
GROUP BY #RFM_FINAL.Customer_Segmentation,Region, A.total_customers
ORDER BY #RFM_FINAL.Customer_Segmentation,customer_percent DESC ;

--Majority of 
--Champion,Active Customers, Cant_lose are from "West"
--At Risk Customers are from "East"
--New Customers, Potential Loyalists, and Hibernating Customers are from "Central"
--Lost customers are from "South"