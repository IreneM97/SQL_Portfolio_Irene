-- Data covers From 2011 to 2017
-- --From July 9, 2011 to July 6,2017

-- Data preparation 

-- Joining 4 tables
SELECT course_id, course_title, url, price,num_subscribers,num_reviews,num_lectures,level,rating, content_duration,
published_timestamp,subject
INTO #udemycombined
FROM (SELECT * FROM dbo.udemy_business
UNION 
SELECT * FROM dbo.udemy_design
UNION 
SELECT * FROM dbo.udemy_music
UNION 
SELECT * FROM dbo.udemy_webdev) AS A


-- CREATING final temptable 
SELECT udemy.coursenumber, udemy.course_title, udemy.url, udemy.price, 
udemy.num_subscribers, udemy.num_reviews, udemy.num_lectures, udemy.level, 
udemy.rating, udemy.content_duration,
udemy.published_timestamp, date, udemy.subject, version 
INTO #udemy_final
FROM (SELECT #udemycombined.course_id AS coursenumber , #udemycombined.course_title, #udemycombined.url, #udemycombined.price, 
#udemycombined.num_subscribers, #udemycombined.num_reviews, #udemycombined.num_lectures, #udemycombined.level, 
#udemycombined.rating, #udemycombined.content_duration,
#udemycombined.published_timestamp, date, #udemycombined.subject, version  FROM #udemycombined
LEFT JOIN dbo.project_sheet
ON #udemycombined.course_id= dbo.project_sheet.course_id)AS udemy

SELECT * FROM #udemy_final

DELETE FROM #udemy_final 
WHERE coursenumber IS NULL;

-- 5 most popular courses in webdev category

--Extracting top 10 courses from each category

SELECT * FROM 
(SELECT *, ROW_NUMBER() OVER (PARTITION BY Subject ORDER BY num_subscribers DESC) as rowno FROM #udemy_final) AS A
WHERE rowno BETWEEN 1 AND 10;


--words like complete, bootcamp,beginner, ultimate, from scratch, pro, basic seems to be used often in these top 10 classes 
-- let's see how many % of top 10 courses have these words in course titles and have impact on popularity?

WITH CTE AS (SELECT * FROM 
(SELECT *, ROW_NUMBER() OVER (PARTITION BY Subject ORDER BY num_subscribers DESC) as rowno FROM #udemy_final) AS A
WHERE rowno BETWEEN 1 AND 10),
CTE2 AS (SELECT 
CASE WHEN course_title LIKE '%Complete%' THEN 'Complete'
WHEN course_title LIKE '%bootcamp%' THEN 'Bootcamp'
WHEN course_title LIKE '%beginner%' THEN  'Beginner'
WHEN course_title LIKE '%from scratch%' THEN 'Scratch'
WHEN course_title LIKE '%basic%' THEN 'Basic'
WHEN course_title LIKE '%pro%' THEN 'Pro' ELSE 'others' END AS Keywords FROM CTE)
SELECT Keywords, COUNT(*) Keywords_Count FROM CTE2
GROUP BY Keywords;

WITH CTE AS (SELECT * FROM 
(SELECT *, ROW_NUMBER() OVER (PARTITION BY Subject ORDER BY num_subscribers DESC) as rowno FROM #udemy_final) AS A
WHERE rowno BETWEEN 1 AND 10)
SELECT ROUND(100*(CAST (COUNT(*) AS numeric)/(SELECT COUNT(*) FROM CTE)),2) AS popular_words_percent  FROM CTE
WHERE course_title LIKE '%Complete%' OR course_title LIKE '%bootcamp%' OR 
course_title LIKE '%beginner%' OR course_title LIKE '%from scratch%' OR course_title LIKE '%basic%' OR course_title LIKE '%pro%'

-- 50% of top 10 courses from each category have words "complete, bootcamp,beginner, ultimate, from scratch, pro, basic" in their titles.


-- Does price affect on popularity ?
SELECT price, SUM(num_subscribers) AS total_subscribers FROM #udemy_final
GROUP BY price
ORDER BY total_subscribers DESC
-- Top 3 prices with most subscribers are 0(free), $20 and $200 with total subscribers of 360K, 135K and 133K accordingly.
-- This proves that customers are willing to pay for quality content if they think it's worth for their money.


--does rating affect on popularity?
-- we have 100 distinct ratings so it will be classified into group and find total subscribers 

SELECT 
SUM(CASE WHEN rating IN(0, NULL) THEN num_subscribers ELSE NULL END) AS zero,
SUM(CASE WHEN rating BETWEEN 0.01 AND 0.4 THEN num_subscribers ELSE NULL END) AS low,
SUM(CASE WHEN rating BETWEEN 0.41 AND 0.75 THEN num_subscribers ELSE NULL END) AS medium,
SUM(CASE WHEN rating > 0.75 THEN num_subscribers ELSE NULL END) AS high
FROM #udemy_final

-- It's obvious that customers care about ratings when it comes to choosing courses. 
-- Courses with high rating (which is 0.75 and above) tend to get more around 50% of customers than courses with low rating
--(which is betwen 0.01 AND 0.4). 

--Courses at which level attract get subscribition most?
SELECT level, SUM(num_subscribers) as total_subscribers FROM #udemy_final
GROUP BY level
ORDER BY total_subscribers DESC
--Courses targeted at all levels get the highest subscriptions, which can be a great insight into generating more revenue.
--The more approachable the course is to people of all levels, the higher the subscription rate is.


--Does course duration matter when it comes to popularity?
SELECT 
SUM(CASE WHEN content_duration <1 THEN num_subscribers ELSE NULL END) AS 'under 1 hour',
SUM(CASE WHEN content_duration BETWEEN 1 AND 20 THEN num_subscribers ELSE NULL END) AS '1 to 20 hour',
SUM(CASE WHEN content_duration BETWEEN 20.5 AND 49 THEN num_subscribers ELSE NULL END) AS '20.5 to 49 hour',
SUM(CASE WHEN content_duration BETWEEN 50 AND 80 THEN num_subscribers ELSE NULL END) AS 'more than 50'
FROM #udemy_final;


-- does popularity drop based on time? Do courses established years ago still interest subscribers or new courses tend to 
-- attract more?

WITH CTE AS (SELECT YEAR(date) as course_published_date, 
COUNT(coursenumber) as total_courses,
SUM(num_subscribers) as TY_subscribers FROM #udemy_final
GROUP BY YEAR(date)),
CTE2 AS (SELECT *, LAG(TY_subscribers) OVER (ORDER BY course_published_date) AS LY_subscribers FROM CTE)
SELECT *, (SUM(TY_subscribers - LY_subscribers)/LY_subscribers) AS YOY_growth,
((TY_subscribers - (SELECT TY_subscribers FROM CTE2 WHERE course_published_date= 2011)))/
(SELECT TY_subscribers FROM CTE2 WHERE course_published_date= 2011) AS growth_comparision_to_1styear FROM CTE2 
GROUP BY course_published_date, TY_subscribers, LY_subscribers, total_courses ;

--Looking at YOY growth and growth comparision to 1st year , apparently courses established in very prior years are less popular (in terms of number of subscribers) 
--than those published in past recent years (such as 2014,2015 and 2016). 
--On the other hand, it is important to note that it can also be depending on
--the number of courses in very prior years are far less than those of past recent years (45 courses in 2012 -1014 courses in 2015)


-- Impact of number of lectures on price or rating? 
-- as we have more than 200 distinct lecture numbers so they will be classified nto group 

SELECT 
ROUND(AVG(CASE WHEN num_lectures <25 THEN price ELSE NULL END),2) AS L_under_25,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 25 AND 49 THEN price ELSE NULL END),2) AS L25_59,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 50 AND 74 THEN price ELSE NULL END),2) AS L50_74,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 75 AND 99 THEN price ELSE NULL END),2) AS L75_99,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 100 AND 124 THEN price ELSE NULL END),2) AS L100_124,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 125 AND 149 THEN price ELSE NULL END),2) AS L125_149,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 151 AND 174 THEN price ELSE NULL END),2) AS L150_174,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 175 AND 199 THEN price ELSE NULL END),2) AS L175_199,
ROUND(AVG(CASE WHEN num_lectures >= 200 THEN price ELSE NULL END),2) AS L_200
FROM #udemy_final

SELECT 
ROUND(AVG(CASE WHEN num_lectures <25 THEN rating ELSE NULL END),2) AS under_25,
ROUND(AVG(CASE WHEN num_lectures BETWEEN 25 AND 49 THEN rating ELSE NULL END),2) AS '25_59',
ROUND(AVG(CASE WHEN num_lectures BETWEEN 50 AND 74 THEN rating ELSE NULL END),2) AS '50_74',
ROUND(AVG(CASE WHEN num_lectures BETWEEN 75 AND 99 THEN rating ELSE NULL END),2) AS '75_99',
ROUND(AVG(CASE WHEN num_lectures BETWEEN 100 AND 124 THEN rating ELSE NULL END),2) AS '100_124',
ROUND(AVG(CASE WHEN num_lectures BETWEEN 125 AND 149 THEN rating ELSE NULL END),2) AS '125_149',
ROUND(AVG(CASE WHEN num_lectures BETWEEN 151 AND 174 THEN rating ELSE NULL END),2) AS '150_174',
ROUND(AVG(CASE WHEN num_lectures BETWEEN 175 AND 199 THEN rating ELSE NULL END),2) AS '175_199',
ROUND(AVG(CASE WHEN num_lectures >= 200 THEN rating ELSE NULL END),2) AS '200_above_avg_price'
FROM #udemy_final
 

--We can see that the prices of courses are charged according to the number of lectures customers receive. 
--Meanwhile, no significant increase or decrease occurred in ratings compared to number of lectures so no amount of lectures does not impact customers' ratings.


SELECT level, ROUND(AVG(price),2) average_price_per_level FROM #udemy_final
GROUP BY level;
-- Prices are not charged depending on level of the course.


--does price affect on rating?
SELECT price, ROUND(AVG(rating),2) average_rating_per_price FROM #udemy_final
GROUP BY price
ORDER BY price ASC;
-- From there we can see that, customers ratings are not based on how much money they have to pay.
-- In other words, just because it's a free or less expensive course , it doesn't mean that customers will give good ratings.
-- As of comparison, courses at $20 recieved average rating of 0.63 while courses at $155 receive that of 0.89.


-- does course duration matter when it comes to popularity(in terms of subscribers)?
SELECT 
SUM(CASE WHEN content_duration <1 THEN num_subscribers ELSE NULL END) AS 'under 1 hour',
SUM(CASE WHEN content_duration BETWEEN 1 AND 20 THEN num_subscribers ELSE NULL END) AS '1 to 20 hour',
SUM(CASE WHEN content_duration BETWEEN 20.5 AND 49 THEN num_subscribers ELSE NULL END) AS '20.5 to 49 hour',
SUM(CASE WHEN content_duration BETWEEN 50 AND 80 THEN num_subscribers ELSE NULL END) AS 'more than 50'
FROM #udemy_final;

-- apparently, courses which are betwen 1-20 hours have the highest number of subscribers 
--in contrast to courses with more than 50 hours duration have the lowest subscribers.
-- This can be a great opportunity for course creator to consider whether designing a new course or polishing existing course.

-- Does content duration matters in setting the price?

SELECT 
ROUND(AVG(CASE WHEN content_duration <1 THEN price ELSE NULL END),2) AS 'under 1 hour',
ROUND(AVG(CASE WHEN content_duration BETWEEN 1 AND 20 THEN price ELSE NULL END),2) AS '1 to 20 hour',
ROUND(AVG(CASE WHEN content_duration BETWEEN 20.5 AND 49 THEN price ELSE NULL END),2) AS '20.5 to 49 hour',
ROUND(AVG(CASE WHEN content_duration BETWEEN 50 AND 80 THEN price ELSE NULL END),2) AS 'more than 50'
FROM #udemy_final;
-- Same as relationship between number of lectures and price, 
-- In general, prices of courses tend to be charged based on course duration.
-- Customers can expect that the longer the course duration is, the more expenseive the price will be.
-- Average price of course under 1 hr = $36.58 Vs course with 1 to 20 hour $57.09

--does udemy course prices get expensive over time ?

SELECT YEAR(date) AS YEAR, ROUND(AVG(price),2) AS Average_price FROM #udemy_final
GROUP BY YEAR(date);
-- nope

-- which level of courses tend to be free/paid?
SELECT version, level, COUNT(coursenumber) AS number_of_courses
FROM #udemy_final
GROUP BY version, level
ORDER BY COUNT(coursenumber) DESC;

-- at any level, udemy have more paid courses than free ones.

