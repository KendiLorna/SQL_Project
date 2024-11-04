/*1. Selecting the employee_name column
replacing the space with a full stop
make it lowercase
and stitch it all together
update employee table with email addresses and pull up table to confirm changes*/

USE md_water_services;

SELECT employee_name,
POSITION(" " IN employee_name) AS Space,
LOWER(REPLACE(employee_name," ",".")) AS First_last,
CONCAT(LOWER(REPLACE(employee_name," ",".")),"@ndogowater.gov") AS Email_addresses
FROM employee;

SET SQL_SAFE_UPDATES=0;

UPDATE employee
SET Email=CONCAT(LOWER(REPLACE(employee_name," ",".")),"@ndogowater.gov");
SELECT * FROM employee;

-- Determine phone number string length then trim whitespace & update in the table
SELECT phone_number FROM employee;
SELECT phone_number,
LENGTH(phone_number) AS Length, 
TRIM(phone_number) AS Phone_number,
LENGTH(TRIM(phone_number)) AS Updated_length
FROM employee;

UPDATE employee 
SET Phone_number=TRIM(phone_number) 
WHERE phone_number;


-- Use the employee table to count how many of our employees live in each town.
/*There are 9 towns,Rural has 29(highest) Yaounde and Kintampo have 1 each(lowest)*/
SELECT* FROM employee;

SELECT DISTINCT town_name,
Count(town_name) AS number_of_employees
FROM Employee
GROUP BY town_name
ORDER BY COUNT(town_name) DESC;

/*So let's use the database to get the
employee ids and use those to get the names, email and phone numbers of the three field surveyors with the most location visits ID( 1,30 and 34)
'Amara Jengo', '+99637993287', 'amara.jengo@ndogowater.gov'
'Pili Zola', '+99822478933', 'pili.zola@ndogowater.gov'
'Rudo Imani', '+99046972648', 'rudo.imani@ndogowater.gov'
*/
SELECT * FROM visits;
SELECT * FROM employee;

SELECT 
DISTINCT assigned_employee_id,
COUNT(visit_count)
FROM visits
GROUP BY assigned_employee_id 
ORDER BY COUNT(visit_count) DESC
LIMIT 3;

SELECT 
	employee_name,
	phone_number,
    email
FROM employee
WHERE assigned_employee_id =1 OR assigned_employee_id =30 OR assigned_employee_id =34;

-- Analysing Locations.Create a query that counts the number of records per TOWN 25 towns,then Per PROVINCE 5 provinces

SELECT * FROM md_water_services.location;
SELECT 
province_name,
town_name,
COUNT(town_name) AS Records_per_town
FROM location
GROUP BY province_name, town_name 
ORDER BY COUNT(town_name)DESC;

SELECT DISTINCT province_name FROM location;

SELECT
province_name,
COUNT(province_name) AS Records_per_province
FROM location
GROUP BY province_name
ORDER BY COUNT(province_name) DESC;
-- Employees per town per province--
SELECT
	province_name,
	town_name,
COUNT(employee_name) AS employees_per_town
FROM employee
GROUP BY province_name,town_name
ORDER BY province_name ASC,COUNT(employee_name) DESC;

/* 1. Create a result set showing:
• province_name
• town_name
• An aggregated count of records for each town (consider naming this records_per_town).
• Ensure your data is grouped by both province_name and town_name.
2. Order your results primarily by province_name. Within each province, further sort the towns by their record counts in descending order.
These results show us that our field surveyors did an excellent job of documenting the status of our country's water crisis. Every province and town
has many documented sources(RURAL IS MORE)
This makes me confident that the data we have is reliable enough to base our decisions on. This is an insight we can use to communicate data
integrity, so let's make a note of that.*/

SELECT
	province_name,
	town_name,
COUNT(town_name) AS records_per_town
FROM location
GROUP BY province_name,town_name
ORDER BY province_name ASC,COUNT(town_name) DESC;

-- Finally, look at the number of records for each location type.Insight <more sources in rural(59.8739%) than urban(40.1261%)> 
SELECT 
DISTINCT location_type, 
COUNT(location_type)AS number_sources
FROM location
GROUP BY location_type ;

SELECT 23740 / (15910 + 23740) * 100 as rural_percentage;
SELECT 100-( 23740 / (15910 + 23740) * 100) as urban_percentage;

-- Diving into water sources
/*How many people are getting water from each type of source? 
INSIGHT a.<Shared tap serve the most 11,945,272 AND Rivers the least 2,362,544>
b.Each record of water source has a unique source_id*/

SELECT * FROM water_source;
SELECT 
DISTINCT  type_of_water_source ,
SUM(number_of_people_served) AS People_per_source
FROM water_source
GROUP BY type_of_water_source 
ORDER BY SUM(number_of_people_served) DESC;

-- 1. How many people did we survey in total?27,628,140
SELECT
SUM(number_of_people_served) AS Total_pop_surveyed
FROM water_source ;

-- 2. How many wells>17383 taps>7265+5856+5767=18888 and rivers>3379 are there?
SELECT
	type_of_water_source,
COUNT(type_of_water_source) AS Count_of_water_sources
FROM water_source
GROUP BY type_of_water_source
ORDER BY COUNT(type_of_water_source) DESC;

-- 3. How many people share particular types of water sources on average?
/*sum of people served per source type/count of source type
 Tap=1081.3147 Tap in home 644/6=100 */
-- Average per source table
SELECT 
DISTINCT  type_of_water_source ,
ROUND(SUM(number_of_people_served)/COUNT(type_of_water_source)) AS Avg_people_per_source
FROM water_source
GROUP BY type_of_water_source 
ORDER BY SUM(number_of_people_served) DESC;

/*Converting people per source into percentages,to 0 decimal places.
Insights: tap in home+ tap in home broken=31% but 14% of the 31% dont have water due to infrastructure issues
wells are 18% but only 4916 are clean out of 17383(28%)*/
SELECT DISTINCT  type_of_water_source ,
ROUND(((SUM(number_of_people_served)/27628140)*100),0)  AS Percentage_people_per_source
FROM water_source
GROUP BY type_of_water_source ;

-- Starting our solution
/*A.Ranking sources per number of people served
sources in order of pop served desc:shared tap,well,tap in home,tap in home broken,river*/
SELECT
DISTINCT  type_of_water_source ,
SUM(number_of_people_served) AS people_served,
RANK() OVER (ORDER BY SUM(number_of_people_served)DESC ) AS Rank_by_population
FROM water_source
GROUP BY type_of_water_source ;

/* B. 1.The sources within each type should be assigned a rank.
2. Limit the results to only improvable sources (SHARED_TAP,TAP_IN_HOME_BROKEN AND WELLS)
3. Think about how to partition, filter and order the results set.
4. Order the results to see the top of the list. 
BY RANKING DESC BY PEOPLE SERVED(Each source id gets grouped but ties have same rank, and skips next number can be confusing to filter )
BY DENSE_RANK DESC BY PEOPLE SERVED(Best in this case in my opinion since ties get same number but it also doesn't skip the next number) 
BY ROW_NUMBER DESC BY PEOPLE SERVED(Each source group gets ordered within itself,ties get distinct numbers can cause bias and confusion)*/
SELECT
	source_id,
    type_of_water_source,
SUM(number_of_people_served) AS people_served,
RANK() OVER (PARTITION BY type_of_water_source ORDER BY SUM(number_of_people_served)DESC ) AS Rank_by_population
FROM water_source
GROUP BY source_id;

-- Filtering source_id and sources Ranked 1-2 using a CTE
WITH Ranked_water_sources AS(
							SELECT
								source_id,
								type_of_water_source,
							SUM(number_of_people_served) AS people_served,
							DENSE_RANK() OVER (PARTITION BY type_of_water_source ORDER BY SUM(number_of_people_served)DESC ) AS Rank_by_population
							FROM water_source
							GROUP BY source_id)
SELECT
	source_id,
    type_of_water_source
FROM Ranked_water_sources
WHERE Rank_by_population<3;

-- Analysing queues.
/*1. How long did the survey take? 924 days */
SELECT
time_of_record, 
Last_value(time_of_record) OVER() AS Final_date,
First_value(time_of_record) OVER() AS Start_date,
DATEDIFF(Last_value(time_of_record) OVER(),First_value(time_of_record) OVER()) AS Duration
FROM visits
LIMIT 1;

/*2:Let's see how long people have to queue on average in Maji Ndogo. Keep in mind that many sources like taps_in_home have no queues. These
are just recorded as 0 in the time_in_queue column, so when we calculate averages, we need to exclude those rows. approx 124 Minutes*/
SELECT * FROM VISITS;
SELECT 
AVG(NULLIF(time_in_queue,0)) AS Avg_visits
FROM visits;

/*3:So let's look at the queue times aggregated across the different days of the week.
Saturday highest=246,Monday second=137,Wednesday low=97,Sunday=82*/  
SELECT
DAYNAME(time_of_record) AS Day_of_week, 
ROUND(AVG(NULLIF(time_in_queue,0))) AS Avg_queue_time 
FROM  visits
GROUP BY DAYNAME(time_of_record)
ORDER BY ROUND(AVG(NULLIF(time_in_queue,0))) DESC;

/*4.We can also look at what time during the day people collect water. Try to order the results in a meaningful way.
7PM has most at 168,(6am,7am,8am and 5pm is second at 149) (Early morning and evening),Time of day with least queue is 111 at 11.00 AM */

SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS Hour_of_day, 
ROUND(AVG(NULLIF(time_in_queue,0))) AS Avg_queue_time 
FROM  visits
GROUP BY TIME_FORMAT(TIME(time_of_record), '%H:00')
ORDER BY  TIME_FORMAT(TIME(time_of_record), '%H:00');

-- Creating a pivot table with all days
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END),0) AS Sunday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END),0) AS Monday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END),0) AS Tuesday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END),0) AS Wednesday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END),0) AS Thursday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END),0) AS Friday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END),0) AS Saturday
FROM visits
WHERE time_in_queue != 0 
GROUP BY TIME_FORMAT(TIME(time_of_record), '%H:00')
ORDER BY TIME_FORMAT(TIME(time_of_record), '%H:00');
