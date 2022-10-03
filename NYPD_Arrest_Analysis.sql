--Data Set Source from NYC OpenData Portal
--https://data.cityofnewyork.us/Public-Safety/NYPD-Arrests-Data-Historic-/8h9b-rp9u
--https://data.cityofnewyork.us/Public-Safety/NYPD-Arrest-Data-Year-to-Date-/uip8-fykc
--Majority of Data Cleaning was done in Excel

--Cleaning Data 
DELETE FROM dbo.NYPD_Arrest_YTD
WHERE KY_CD IS NULL OR PD_CD IS NULL;

DELETE FROM NYPD_Arrest_Historic
WHERE KY_CD IS NULL OR PD_CD IS NULL;

--Union two tables and creating temp table
SELECT ARREST_KEY, ARREST_DATE, PD_CD, PD_DESC, KY_CD, OFNS_DESC, LAW_CODE, LAW_CAT_CD, ARREST_BORO, ARREST_PRECINCT,
JURISDICTION_CODE, AGE_GROUP, PERP_SEX, PERP_RACE, X_COORD_CD, Y_COORD_CD, Latitude, Longitude 
INTO #NYPD_Arrests_Data
FROM (SELECT * FROM dbo.NYPD_Arrest_YTD
UNION ALL
SELECT * FROM dbo.NYPD_Arrest_Historic) AS A;

SELECT * FROM #NYPD_Arrests_Data

--Inspecting Year in dataset
SELECT DISTINCT(YEAR(Arrest_Date)) FROM #NYPD_Arrests_Data
ORDER BY YEAR(Arrest_Date);
--From January 2006 to End of June 2022

--Inspecting types of Offense

SELECT DISTINCT(OFNS_DESC) FROM #NYPD_Arrests_Data
ORDER BY OFNS_DESC;

--Inspecting total number of each offense

SELECT KY_CD, OFNS_DESC, COUNT(*) FROM #NYPD_Arrests_Data
GROUP BY OFNS_DESC,KY_CD
ORDER BY 3 DESC;

--Inspecting which level of offense happens most

SELECT LAW_CAT_CD AS level_of_offense, COUNT(*) As total_number FROM #NYPD_Arrests_Data
WHERE LAW_CAT_CD IS NOT NULL AND LAW_CAT_CD != 'I'
GROUP BY LAW_CAT_CD 
ORDER BY 2 DESC;
--Misdemeanor is the most common offense

--Which age group commit the offenses the most 
SELECT Age_group,  COUNT(*) As total_number_of_arrests FROM #NYPD_Arrests_Data 
WHERE AGE_GROUP IN ('25-44','18-24','<18','45-64','65+')
GROUP BY Age_group
ORDER BY total_number_of_arrests DESC;

--which age group ranks highest in each level of offense 
WITH CTE AS(SELECT LAW_CAT_CD, Age_group, COUNT(*) AS total_num FROM #NYPD_Arrests_Data 
WHERE AGE_GROUP IN ('25-44','18-24','<18','45-64','65+') AND LAW_CAT_CD IS NOT NULL AND LAW_CAT_CD != 'I'
GROUP BY Age_group,LAW_CAT_CD),
CTE2 AS (SELECT LAW_CAT_CD, MAX(total_num) As total_arrests FROM CTE 
GROUP BY LAW_CAT_CD)
SELECT CTE2.LAW_CAT_CD, Age_group, CTE2.total_arrests FROM CTE2
JOIN CTE
ON CTE2.total_arrests = CTE.total_num;
--Age between 25-44 ranks highest in all levels of offense: felony, misdemeanor, violence

--Inspecting which year has the highest arrests 
SELECT YEAR(Arrest_Date) As record_year, COUNT(*) As total_number_of_arrests FROM #NYPD_Arrests_Data
GROUP BY YEAR(Arrest_Date)
ORDER BY 2 DESC;
--Top 3 year with highest arrests are 2006,2018 & 2019

--Inspecting which neighborhood had the most arrests
SELECT ARREST_BORO, COUNT(*) as total_number_of_arrests FROM #NYPD_Arrests_Data
GROUP BY ARREST_BORO
ORDER BY 2 DESC;
--Brooklyn ranks at 1st, followed by Manhattan and Bronx

--Rolling Number of arrests in each neighborhood by each date

WITH CTE2 AS (SELECT arrest_boro, CAST(arrest_date AS DATE) AS ADATE, COUNT(*) AS Daily_Arrest FROM #NYPD_Arrests_Data
GROUP BY arrest_boro, CAST(arrest_date AS DATE))
SELECT Arrest_Boro, ADate,Daily_Arrest, SUM(Daily_Arrest) OVER (PARTITION BY Arrest_Boro ORDER BY ADATE) AS Rolling_Sum FROM CTE2
GROUP BY  Arrest_Boro, ADate, Daily_Arrest
ORDER BY Arrest_Boro, ADate;
--created both per-day number and rolling sum so that we can easily look at how many people in total have been arrested till specific date
--in each neighborhood

--Pivoting Table - Total Number of Arrests on each Age Group by each year 
SELECT Age_group,
COUNT(CASE WHEN YEAR(Arrest_Date)= 2006 THEN Arrest_Key ELSE NULL END) AS '2006',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2007 THEN Arrest_Key ELSE NULL END) AS '2007',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2008 THEN Arrest_Key ELSE NULL END) AS '2008',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2009 THEN Arrest_Key ELSE NULL END) AS '2009',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2010 THEN Arrest_Key ELSE NULL END) AS '2010',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2011 THEN Arrest_Key ELSE NULL END) AS '2011',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2012 THEN Arrest_Key ELSE NULL END) AS '2012',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2013 THEN Arrest_Key ELSE NULL END) AS '2013',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2014 THEN Arrest_Key ELSE NULL END) AS '2014',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2015 THEN Arrest_Key ELSE NULL END) AS '2015',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2016 THEN Arrest_Key ELSE NULL END) AS '2016',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2017 THEN Arrest_Key ELSE NULL END) AS '2017',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2018 THEN Arrest_Key ELSE NULL END) AS '2018',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2019 THEN Arrest_Key ELSE NULL END) AS '2019',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2020 THEN Arrest_Key ELSE NULL END) AS '2020',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2021 THEN Arrest_Key ELSE NULL END) AS '2021',
COUNT(CASE WHEN YEAR(Arrest_Date)= 2022 THEN Arrest_Key ELSE NULL END) AS '2022'
FROM #NYPD_Arrests_Data
WHERE AGE_GROUP IN ('25-44','18-24','<18','45-64','65+') 
GROUP BY Age_group
ORDER BY Age_Group;
--This gives granularity on total number offenses committed by each group year by year


--Total Number of Arrests VS Sex
SELECT Perp_Sex, COUNT(*) As total_number FROM #NYPD_Arrests_Data
GROUP BY Perp_Sex
ORDER BY 2 DESC;
--Males committed more offenses than female

--Total Number of Arrests VS Race
SELECT Perp_Race, COUNT(*) As total_number FROM #NYPD_Arrests_Data
GROUP BY Perp_Race
ORDER BY 2 DESC;


