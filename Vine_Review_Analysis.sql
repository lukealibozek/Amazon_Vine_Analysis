-- CREATE TABLE vine_table (
--   review_id TEXT PRIMARY KEY,
--   star_rating INTEGER,
--   helpful_votes INTEGER,
--   total_votes INTEGER,
--   vine TEXT,
--   verified_purchase TEXT
-- );

--------------------------------
-- Filter to reviews with 20 or more votes
--------------------------------
-- SELECT * 
-- 	INTO twenty_plus_votes
-- FROM vine_table
-- 	WHERE total_votes >= 20

--------------------------------
-- Filter to reviews 50% or more helpful votes 
--------------------------------
-- SELECT *
--   	INTO helpful_vine
-- FROM twenty_plus_votes
-- 	WHERE CAST(helpful_votes AS FLOAT)/CAST(total_votes AS FLOAT) >=0.5

--------------------------------
-- Count values in each table
--------------------------------
-- SELECT (SELECT COUNT(review_id) FROM twenty_plus_votes) as TwentyPlus, 
-- (SELECT COUNT(review_id) FROM helpful_vine) as Helpful

--------------------------------
-- Filter to vine = y
--------------------------------
-- SELECT *
-- INTO vine_Yes
-- FROM helpful_vine
-- WHERE vine = 'Y'

--------------------------------
-- Filter to vine = n
--------------------------------
-- SELECT *
-- INTO vine_No
-- FROM helpful_vine
-- WHERE vine = 'N'

--------------------------------
-- Count to Total 5 Star
--------------------------------
-- SELECT COUNT(review_id) 
-- INTO five_star_helpful
-- FROM helpful_vine 
-- WHERE star_rating = 5


--------------------------------
-- Sanity Check: values in each table
--------------------------------
-- SELECT (SELECT COUNT(review_id) FROM twenty_plus_votes) as Filtered_to_TwentyPlus, 
-- (SELECT COUNT(review_id) FROM helpful_vine) as Filtered_to_Helpful,
-- (SELECT COUNT(review_id) FROM vine_Yes) as vine_Yes,
-- (SELECT COUNT(review_id) FROM vine_No) as vine_No

--------------------------------
-- Totals for Deliverable
--------------------------------
SELECT (SELECT COUNT(review_id) FROM helpful_vine) as "Total Votes(w/ 20+ votes, 50%+ Helpful Rating)",
(SELECT COUNT(review_id) FROM helpful_vine where star_rating = 5) as "Total 5 Star Ratings",
CAST((SELECT COUNT(review_id) FROM helpful_vine where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM helpful_vine) AS FLOAT) * 100 as "% of 5 Star Reviews",
(SELECT COUNT(review_id) FROM vine_Yes) as "Total Vine=Y Votes",
(SELECT COUNT(review_id) FROM vine_Yes where star_rating = 5) as "Total 5 Star Vine=Y Votes",
CAST((SELECT COUNT(review_id) FROM vine_Yes where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM vine_Yes) AS FLOAT) * 100 as "% of Vine=Y 5 Star Reviews",
(SELECT COUNT(review_id) FROM vine_No) as "Total Vine=N Votes",
(SELECT COUNT(review_id) FROM vine_No where star_rating = 5) as "Total 5 Star Vine=N Votes",
CAST((SELECT COUNT(review_id) FROM vine_No where star_rating = 5) AS FLOAT) / CAST((SELECT COUNT(review_id) FROM vine_No) AS FLOAT) * 100 as "% of Vine=N 5 Star Reviews"


--  	sum(case when vine = 'Y' AND star_rating = 5 then 1 else 0 end) as "Total_5_Star_w_Vine",
-- 	(SELECT "Total_5_Star_w_Vine") / (SELECT Total_5_Star) as "what",
-- -- 	CAST(sum(case when vine = 'Y' AND star_rating = 5 then 1 else 0 end) AS FLOAT) / CAST(sum(case when star_rating = 5 then 1 else 0 end) AS FLOAT)*100 AS "% Total w/ Vine",
-- 	sum(case when vine = 'N' AND star_rating = 5 then 1 else 0 end) as "Total 5 Star w/o Vine",
-- 	CAST(sum(case when vine = 'N' AND star_rating = 5 then 1 else 0 end) AS FLOAT) / CAST(sum(case when star_rating = 5 then 1 else 0 end) AS FLOAT)*100 AS "% Total w/o Vine"
-- 	FROM vine_d2_2	