--Friends TV show Data Set From Kaggle https://www.kaggle.com/datasets/ruchi798/friends-tv-show-all-seasons-and-episodes-data
-- Some data cleaning were done in Excel.

--Updating some missing information in the table
UPDATE friends
SET Directed_by= 'Lorna Devis'
WHERE season = 10 AND Episode = 'Special'

UPDATE friends
SET Written_by= 'Marta Kauffman & David Crane'
WHERE season = 10 AND Episode = 'Special'

UPDATE friends
SET Directed_By = 'Kevin S. Bright'
WHERE season = 7 AND Episode = 'Special'


SELECT * FROM friends;

--Total episodes of the show

SELECT COUNT(*) AS total_episodes FROM Friends;
--238

--Total episodes per season
SELECT season, COUNT(*) AS total_episodes FROM Friends
GROUP BY season;

--which season has the average highest viewers
SELECT season, ROUND(AVG(US_viewers),2) AS average_viewers FROM Friends
GROUP BY season
ORDER BY 2 DESC;
--S2

--which season has the average and total highest viewers
SELECT season, ROUND(SUM(US_viewers),2) AS total_viewers, ROUND(AVG(US_viewers),2) AS average_viewers  FROM Friends
GROUP BY season
ORDER BY 2 DESC;
--S2

--which episode has the highest viewers/share 
SELECT * FROM friends WHERE US_viewers --share 
IN (SELECT MAX(US_viewers) FROM friends);
-- The one after the Super Bowl has the both the highest viewers and share of all seasons

--which episode has the lowest viewers/share
SELECT * FROM friends WHERE US_viewers --share
IN (SELECT MIN(US_viewers) FROM friends);
-- 'The one with the Vows' has the both the lowest viewers and share of all seasons
-- Any correlation between the viewers and share?

--day interval between first episode and last episode
SELECT DATEDIFF(day,MIN(Date), MAX(Date)) AS dateinterval FROM friends;
-- last episode is aired 3514 days after first episode

--directors of the show
SELECT DISTINCT (directed_by) as directors FROM friends;
-- Kevin Bright and Gary Halvorson are the only duo who directed together

-- total number of episodes by director during the show
SELECT Directed_by AS director, COUNT(*) AS total_episodes_overall FROM friends
GROUP BY Directed_by
ORDER BY 2 DESC
-- Suprisingly found out that Actor David Schwimmer who plays the character 'Ross' directed toatl 10 episodes 

-- Details of episodes directed by David Schwimmer
SELECT * FROM friends
WHERE Directed_by = 'David Schwimmer';


--Number of episodes by director in each season 
SELECT Directed_by AS director,
COUNT(CASE WHEN season= 1 THEN directed_by ELSE NULL END) AS Season1,
COUNT(CASE WHEN season= 2 THEN directed_by ELSE NULL END) AS Season2,
COUNT(CASE WHEN season= 3 THEN directed_by ELSE NULL END) AS Season3,
COUNT(CASE WHEN season= 4 THEN directed_by ELSE NULL END) AS Season4,
COUNT(CASE WHEN season= 5 THEN directed_by ELSE NULL END) AS Season5,
COUNT(CASE WHEN season= 6 THEN directed_by ELSE NULL END) AS Season6,
COUNT(CASE WHEN season= 7 THEN directed_by ELSE NULL END) AS Season7,
COUNT(CASE WHEN season= 8 THEN directed_by ELSE NULL END) AS Season8,
COUNT(CASE WHEN season= 9 THEN directed_by ELSE NULL END) AS Season9,
COUNT(CASE WHEN season= 10 THEN directed_by ELSE NULL END) AS Season10
FROM friends
GROUP BY directed_by
ORDER BY 2 DESC;


-- Ratings
-- A TV show's rating refers to the number of households who tuned in to watch the content 
--as a percentage of the entire population of TV-equipped homes
-- Rating = (number of viewers/total universe of potential viewers)

--Share
--expressed as a percentage of the audience that was actually watching TV at the time .
--Share = (number of viewers/total number of TV watchers)


--which episode has the highest rating of all seasons
SELECT * FROM friends WHERE rating IN 
(SELECT MAX(rating) FROM friends)
-- the last two episodes of Friends have the highest rating of 29.8 out of all episodes

--which episode has the lowest rating 
SELECT * FROM friends WHERE rating IN 
(SELECT MIN(rating) FROM friends)
-- S8 Ep 7 has the lowest rating of 9.6 out of all episodes

-- average, lowest and highest rating generated by each director

SELECT Directed_by AS Director, ROUND(AVG(rating),2) AS Average_viewers, MIN(rating) AS Lowest_rating, MAX(rating) AS Highest_rating FROM friends
GROUP BY directed_by
ORDER BY Highest_rating DESC;
-- Kevin Bright happens to be the one who directed both episodes with highest and lowest rating.

--average rating across all seasons
SELECT season, ROUND(AVG(rating),2) as average_rating FROM friends
GROUP BY season
--S2 with average of 20.51

--Episodes with wedding scenes
SELECT * FROM friends
WHERE title LIKE '%Wedding%'


--After the end of each season, how many day does it take to air first episode of new season?
WITH CTE AS (SELECT season, MIN(DATE) as start_of_new_season, MAX(DATE) AS end_of_previous_season, ROW_NUMBER() OVER (ORDER BY MIN(DATE)) AS row_no
FROM Friends
GROUP BY season),
CTE2 AS (SELECT season, start_of_new_season,
CASE WHEN row_no= 2 THEN (SELECT end_of_previous_season FROM CTE where row_no = 1)
WHEN row_no= 3 THEN (SELECT end_of_previous_season FROM CTE where row_no = 2) 
WHEN row_no= 4 THEN (SELECT end_of_previous_season FROM CTE where row_no = 3) 
WHEN row_no= 5 THEN (SELECT end_of_previous_season FROM CTE where row_no = 4)
WHEN row_no= 6 THEN (SELECT end_of_previous_season FROM CTE where row_no = 5) 
WHEN row_no= 7 THEN (SELECT end_of_previous_season FROM CTE where row_no = 6)
WHEN row_no= 8 THEN (SELECT end_of_previous_season FROM CTE where row_no = 7) 
WHEN row_no= 9 THEN (SELECT end_of_previous_season FROM CTE where row_no = 8)
WHEN row_no= 10 THEN (SELECT end_of_previous_season FROM CTE where row_no = 9)
ELSE NULL
END AS end_of_previous_season FROM CTE)
SELECT season, DATEDIFF(Day, end_of_previous_season, start_of_new_season) AS day_interval_between_season FROM CTE2;
--Season 10 first episode is aired 133 days after final episode of season 9.
