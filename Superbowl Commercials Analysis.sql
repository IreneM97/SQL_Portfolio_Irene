
SELECT * FROM SuperBowlCommercials.dbo.superbowl_commercials;
--Looking at Total Number of Superbowl Ads

SELECT COUNT(*) AS Total_Number_of_commercials FROM SuperBowlCommercials.dbo.superbowl_commercials;
--249 Commericals in total

--Which brand has had the most Super Bowl commercials? Do they have a distinct style?

--Number of Commercials By Brands 
SELECT Brand, COUNT(*) AS Total_Number_of_commercials FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand
ORDER BY 2 DESC;

--Which brand has had the most Super Bowl commercials? Do they have a distinct style?

--Total Number of Funny Commericals By Brand 
SELECT Brand,  CAST(COUNT(*) AS float) AS Total_Number_of_commercials , SUM(CAST(Funny AS float)) AS Total_Number_of_Funny_Ads
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand;

--Looking at Total Funny Ads VS Total Commericals (in Percentage)
SELECT Brand,  CAST(COUNT(*) AS float) AS Total_Number_of_commercials , SUM(CAST(Funny AS float)) AS Num_of_Funny_Ads, 
ROUND((SUM(CAST(Funny AS float))/CAST(COUNT(*) AS float))*100,2) AS Percent_of_Funny_Ads
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand
ORDER BY 4 DESC;

----Total Number of Patriotic Commericals By Brand 

SELECT Brand, COUNT(*) AS Total_Number_of_commercials, SUM(CAST(Patriotic AS FLOAT)) AS Num_of_Patriotic_Ads FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand
ORDER BY 3 DESC;

--Looking Total Patriotic Ads VS Total Commericals (in Percentage)

SELECT Brand, COUNT(*) AS Total_Number_of_commercials, SUM(CAST(Patriotic AS FLOAT)) AS Num_of_Patriotic_Ads, ROUND((SUM(CAST(Patriotic AS FLOAT))/ COUNT(*))*100,2)
AS Percent_of_Patriotic_Ads
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand
ORDER BY 4 DESC;

--How have different characteristics for commercials trended across time?

--Looking at Quick Product Showcase Trend across the years

SELECT Year, COUNT(*) AS total_ads_per_year, SUM(CAST(ShowsProductQuickly AS Float)) AS Quick_Product_Showcase_Count,
ROUND((SUM(CAST(ShowsProductQuickly AS Float))/COUNT(*)) * 100,2) AS Percent_of_Quick_Product_Showcase
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year;

--Looking at Celebrity Usage Trend across the years

SELECT Year, COUNT(*) AS total_ads_per_year, SUM(CAST(Celebrity AS Float)) AS Celebrity_Usage_Count,
ROUND((SUM(CAST(Celebrity AS Float))/COUNT(*)) * 100,2) AS Percent_of_Quick_Product_Showcase
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year;

-- Looking at Sex usage trend over the years

SELECT Year, COUNT(*) AS total_ads_per_year, SUM(CAST(UseSex AS Float)) AS Sex_Usage_Count,
ROUND(SUM(CAST(UseSex AS Float))/COUNT(*)* 100,2) AS Percent_of_Sex_Usage
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year;


-- Looking at Animals usage over the years
SELECT Year, COUNT(*) AS total_ads_per_year, SUM(CAST(Animals AS Float)) AS Animals_Usage_Count,
ROUND(SUM(CAST(Animals AS Float))/COUNT(*)* 100,2) AS Percent_of_Animals_Usage
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year;


-- Looking at danger involvment in ads over the years
SELECT Year, COUNT(*) AS total_ads_per_year, SUM(CAST(Danger AS Float)) AS Danger_Involvement_Count,
ROUND(SUM(CAST(Danger AS Float))/COUNT(*)* 100,2) AS Percent_of_Danger_Involvement
FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year;

--Highest estimated cost of Superbowl Ads each year

SELECT  Year, Max(EstimatedCost) Highest_Estimated_Cost FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year
ORDER BY Year;

--Highest estimated cost of Superbowl Ads and Brands each year
SELECT  Year, Brand, EstimatedCost AS Highest_Cost FROM SuperBowlCommercials.dbo.superbowl_commercials 
WHERE EstimatedCost IN (SELECT Max(EstimatedCost) AS Highest_Estimated_Cost FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year)
ORDER BY Year; 

--Looking at all years numbers

-- Brands with highest spending (in millions) on Superbowl Ads within 21 years (from 2000 to 2021)

SELECT Brand, SUM(EstimatedCost) AS total_spending FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand
ORDER BY total_spending DESC;

--Maximum duration of Superbowl Ads across all years 
SELECT Year, Max(length) AS Max_Duration FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Year;


--Can you identify any patterns for the most successful commercials on YouTube?

--Successful Commercials with Highest Views on Youtube

SELECT Brand, YoutubeLink, YoutubeViews FROM SuperBowlCommercials.dbo.superbowl_commercials
WHERE YoutubeViews IN (SELECT MAX(YoutubeViews) FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY YoutubeLink)
ORDER BY YoutubeViews DESC;



-- Looking at traits of Top 10 Commercials with highest views on YT

SELECT TOP 10 Brand, YoutubeLink, YoutubeViews, length, Funny, ShowsProductQuickly, Celebrity, Patriotic, Danger, Animals, UseSex
FROM SuperBowlCommercials.dbo.superbowl_commercials
WHERE YoutubeViews IN (SELECT MAX(YoutubeViews) FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand)
ORDER BY YoutubeViews DESC;

-- Filtering patterns of Top 10 commericals with highest views on YT
-- looking into which characteristics are used to which extent in those ads

WITH CTE(Brand, YoutubeLink, YoutubeViews, Funny, ShowsProductQuickly, Celebrity, Patriotic, Danger, Animals, UseSex)
AS(
SELECT TOP 10 Brand, YoutubeLink, YoutubeViews, Funny, ShowsProductQuickly, Celebrity, 
Patriotic, Danger, Animals, UseSex FROM SuperBowlCommercials.dbo.superbowl_commercials
WHERE YoutubeViews IN (SELECT MAX(YoutubeViews) FROM SuperBowlCommercials.dbo.superbowl_commercials
GROUP BY Brand)
)
SELECT (SUM(CAST(Funny AS float))/ COUNT(*))* 100 AS Funny_Percent,
 (SUM(CAST(ShowsProductQuickly AS float))/ COUNT(*))* 100 AS Product_Percent,
 (SUM(CAST(Celebrity AS float))/ COUNT(*))* 100 AS Celebrity_Percent,
 (SUM(CAST(Patriotic AS float))/ COUNT(*))* 100 AS Patriotic_Percent,
 (SUM(CAST(Danger AS float))/ COUNT(*))* 100 AS Danger_Percent,
 (SUM(CAST(Animals AS float))/ COUNT(*))* 100 AS Animals_Percent,
 (SUM(CAST(UseSex AS float))/ COUNT(*))* 100 AS Sex_Usage_Percent
 FROM CTE;

 --Insights
 -- Among Top 10 ads with highest views on Youtube,
 -- 60% of them show their products quickly in their ads
 -- 50% of them are funny
 -- 40% make patriotoc appeals or  invlove danger
 -- 30% feature celebrities or animals
 -- Only 10% use sex to sell the products 

-- Which characteristics are paired most often? Can you find any unusual combinations?

SELECT COUNT(*) FROM SuperBowlCommercials.dbo.superbowl_commercials
WHERE Funny = 1 AND ShowsProductQuickly =1; 
--121 

SELECT COUNT(*) FROM SuperBowlCommercials.dbo.superbowl_commercials
WHERE Patriotic =1 AND Danger= 1;
--6

SELECT COUNT(*) FROM SuperBowlCommercials.dbo.superbowl_commercials
WHERE Patriotic =1 AND UseSex= 1;
--5

-- Most often paired characteristics are Funny and ShowsProductQuickly (in 121 ads)
-- Least paired characteristics are patriotic and UseSex in 5 ads
-- Least Patriotic and Danger in 6 ads


-- The only ad which features all 7 characteristics
SELECT Brand, Year, SuperbowlAdsLink, YoutubeLink FROM SuperBowlCommercials.dbo.superbowl_commercials
WHERE Funny = 1 AND ShowsProductQuickly =1 AND Celebrity= 1 AND Animals= 1 AND Patriotic= 1 AND UseSex= 1 AND Danger= 1;


