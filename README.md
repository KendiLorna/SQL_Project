## **Maji Ndogo Water Access Survey**
### **INTRODUCTION**

Maji Ndogo is an AI-generated African country facing a water crisis due to persistent corrupt regimes. The country has a new president keen on reversing past governments' damage and restoring Maji Ndogo to its former glory. Maji Ndogo has a population of 28 million people living in the five provinces of Maji Ndogo namely Sokoto, Amanzi, Akatsi, Hawassa, and Kilimani, which between them have a total of 31 towns both urban and rural.

### **USER STORY**

The president set up a government agency to investigate the water sources in the country and they recorded their findings for 924 days( 2 years and 5 months). 
She then proceeded to hire a team of data analysts to investigate the data and provide insights.
The results will help decide on resource allocation and prioritization of projects.

### **OBJECTIVE**

#### Part one objective:

1. Get familiar with the data
2. Analyze the water sources
3. Unpack the visits to water sources
4. Assess the quality of water sources
5. Investigate any pollution issues

#### Part two objective:

1. To identify the water sources people use and determine both the total and average number of users for each source.

2. Examining the duration citizens spend in queues to access water.

#### Part three objective:

1. Addressing data integrity, accuracy,  and reliability of the data.

#### Part four objective:

1. Shaping the raw data into meaningful views to provide essential information to decision-makers.

2. To facilitate budget planning and identify the areas requiring immediate attention.

3. To create a table where repair teams have the information they need to fix, upgrade, and repair water sources and can update progress.

### **DATA SOURCE**

ALX Africa.

A database "md_water_services" SQL text file was provided by ALX Africa for the project.

### **TOOLS**

- MySQL - Data cleaning and analysis.

### **METHODOLOGY**

The project is in four parts with progressive advancement into more complex insights at the end of every part.
#### 1. Data Cleaning
In the initial data preparation phase, the following tasks were performed:
- Data loading and inspection.
- Updating incorrect values.
- Data validation.
- Data cleaning and formatting.

#### 2. Exploratory Data Analysis

The following were the questions of concern:

- The water sources available and the number of people that each serves. 

- The distribution of water sources across rural and urban centers 

- Which provinces and towns are most in need of improvement?

- The number of water sources that need improvement.
#### 3. Data Analysis and Insights

The insights are progressive and divided into four parts.

#### Maji Ndogo Part 1 Insights.

1. There are five unique sources of water in Maji Ndogo: shared taps, taps in homes, wells, rivers, and broken water taps in homes.

```SQL

-- Find the population in Maji_Ndogo by querying the data dictionary(27,628,140)
SELECT *
FROM data_dictionary WHERE description LIKE '%population%' ;
SELECT * FROM global_water_access;
SELECT 
pop_n
FROM global_water_access
WHERE name = 'Maji Ndogo';

```

```SQL
--5 distinct types of water sources
SELECT 
DISTINCT type_of_water_source
FROM md_water_services.water_source;

```

2. Each of the water sources is visited by field surveyors to measure water quality. Only shared taps should have been visited more than once by the government field surveyors to check the quality.
However, we find that 218 water sources with a quality score of 10 were visited more than once which is of concern.

```SQL

/*Records where officials visited more than once and in places with tap water at home(quality score of 10)
The surveyors only made multiple visits to shared taps and did not revisit other types of water sources. So
there should be no records of second visits to locations where there are good water sources, like taps in homes.*/

SELECT
      record_id,
      subjective_quality_score,
      visit_count
FROM md_water_services.water_quality
WHERE subjective_quality_score=10
AND visit_count>1;

```

3. Investigation of the well pollution table reveals mislabeling of 102 wells as clean while they are contaminated which can be dangerous. This was updated to match the description and results.

```SQL
-- Update well pollution table--
UPDATE
well_pollution
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';

UPDATE
well_pollution
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';

UPDATE
well_pollution
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean';

-- Querying if all updates were successful
-- Shows if all previously mislabelled records are successfully updated
SELECT *
FROM md_water_services.well_pollution
WHERE description LIKE 'Clean_%'
OR (biological > 0.01 AND results = 'Clean');

```

#### Maji Ndogo Part 2 Insights

1. Most water sources in Maji Ndogo are in rural parts(60%).

  ````SQL

-- The number of records for each location type.Insight <more sources in rural(59.8739%) than urban(40.1261%)> 
SELECT 
DISTINCT location_type, 
COUNT(location_type)AS number_sources
FROM location
GROUP BY location_type ;

SELECT 23740 / (15910 + 23740) * 100 as rural_percentage;
SELECT 100-( 23740 / (15910 + 23740) * 100) as urban_percentage;

````

2. 43% of the population is using shared taps. Some shared tap sources have a queue time above 500 minutes and an average of 2000 people often share one tap.
3. 31% of the population has water infrastructure in their homes, but within that group, 45% face non-functional systems due to issues with pipes, pumps, and reservoirs.
4. 18% of the people are using wells, but within that, only 28% are clean.

````SQL
   --Percentage population per water source
SELECT DISTINCT  type_of_water_source,
ROUND(((SUM(number_of_people_served)/27628140)*100),0)  AS Percentage_people_per_source
FROM water_source
GROUP BY type_of_water_source ;

````

````SQL

   -- Average people per source
SELECT 
DISTINCT  type_of_water_source ,
ROUND(SUM(number_of_people_served)/COUNT(type_of_water_source)) AS Avg_people_per_source
FROM water_source
GROUP BY type_of_water_source 
ORDER BY SUM(number_of_people_served) DESC;

````
5. Maji Ndogo citizens often face long wait times for water, averaging more than 120 minutes.

````SQL
  --Many sources like taps_in_home have no queues so when we calculate the average, we need to exclude those rows.
SELECT * FROM VISITS;
SELECT 
AVG(NULLIF(time_in_queue,0)) AS Avg_visits
FROM visits;

````

6. In terms of queues: Queues are very long on Saturdays, queues are longer in the mornings and evenings with Wednesdays and Sundays having the shortest queues.

````SQL
 --Queue times aggregated across the different days of the week.
SELECT
DAYNAME(time_of_record) AS Day_of_week, 
ROUND(AVG(NULLIF(time_in_queue,0))) AS Avg_queue_time 
FROM  visits
GROUP BY DAYNAME(time_of_record)
ORDER BY ROUND(AVG(NULLIF(time_in_queue,0))) DESC;
````

### Maji Ndogo Part 3 Insights

1. An independent audit was conducted to address discrepancies observed in part one i.e. water quality scores. The report(auditor’s report) was integrated into the database and it was discovered that 1518/1620(94%) of the records revisited were recorded correctly.

````SQL

-- CREATE A NEW AUDITOR REPORT TABLE AND IMPORT DATA FROM THE CSV FILE INTO IT
CREATE TABLE auditor_report (
location_id VARCHAR(32),
type_of_water_source VARCHAR(64),
true_water_source_score int DEFAULT NULL,
statements VARCHAR(255)
);

/*JOINING AUDITOR REPORT WITH VISITS AND WATER QUALITY TABLES TO COMPARE AUDITED QUALITY SCORE WITH SUBJECTIVE QUALITY SCORE
 1518 CORRESPOND,102 DON'T MATCH*/
SELECT  
auditor_report.location_id AS location_id,
visits.record_id AS record_id,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM auditor_report 
JOIN
visits 
ON auditor_report.location_id=visits.location_id
JOIN 
water_quality
ON visits.record_id=water_quality.record_id
WHERE visits.visit_count=1 
AND auditor_report.true_water_source_score<water_quality.subjective_quality_score;

````

2. The 102 records that had discrepancies were further investigated and using comments by locals from the auditor's report as well as the number of incorrect records, 4 employees were found to be corrupt, and therefore their inspections and results recorded would have to be reviewed.

````SQL

WITH error_count AS (-- This brings up the count of all employees and their mistakes--
    SELECT  
    employee_name,
    COUNT(employee_name) as number_of_mistakes
    FROM incorrect_records
    GROUP BY employee_name
                    ),
                    
Avg_error_count AS(-- This returns a scalar value that is the average of the errors made by employees
    SELECT  
    AVG(number_of_mistakes) AS avg_error_count_per_empl
    FROM error_count
				   ),
                   
Suspect_list AS (-- This returns the four names of employees whose count of mistakes is higher than the average
    SELECT
    employee_name,
    number_of_mistakes
    FROM error_count
    WHERE number_of_mistakes>(SELECT  
                               AVG(number_of_mistakes)
                               FROM error_count)
                 )
                 
SELECT -- This extracts names, locations, and statements by locals from the incorrect_records view of the four employees in the suspect list
DISTINCT employee_name,
location_id,
statements
FROM incorrect_records
WHERE employee_name  IN (SELECT employee_name FROM Suspect_list );

SELECT -- SUBSTITUTE THIS QUERY ABOVE TO CHECK IF THERE ARE ANY EMPLOYEES WITH CASH MENTIONED IN THE STATEMENTS(Only the four in the suspect list do)
DISTINCT	employee_name
FROM incorrect_records
WHERE statements LIKE '%cash%' 
AND employee_name IN((SELECT employee_name
                      FROM error_count
                      WHERE number_of_mistakes> (SELECT  
                                                 AVG(number_of_mistakes) AS avg_error_count_per_empl
                                                 FROM error_count)))
                                                 ORDER BY employee_name;
````

### Maji Ndogo Part 4 Insights

1. Most water sources are in rural parts of Maji Ndogo.A view(combined analysis table is created and queried)
   
````SQL

CREATE VIEW combined_analysis_table AS (SELECT-- The view has details of all water sources in Maji Ndogo
water_source.type_of_water_source AS source_type,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served AS people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
INNER JOIN
water_source ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1);

SELECT location_type,
COUNT(location_type) AS count_of_repairs
FROM combined_analysis_table
GROUP BY location_type
ORDER BY count_of_repairs DESC;-- Most sources are in rural areas(23740).Urban(15910)

````
2. Shared taps are the most common source of water in all five provinces and rivers are the least common with Sokoto having the highest number of river sources.
Most sources in towns in Amanzi are shared taps and Hawassa has the most number of wells.
Most of the water from Amanzi comes from taps, but half of these home taps don't work because the infrastructure is broken.

````SQL

WITH province_totals AS (-- This CTE calculates the population of each province
						SELECT
						province_name,
						SUM(people_served) AS total_ppl_serv
						FROM
						combined_analysis_table
						GROUP BY
						province_name
                        )
                        /* If you replace the query below with this one(SELECT * FROM province_totals
                        ORDER BY total_ppl_serv DESC;), you get a table of province names and summed up populations for each province
                        Kilimani has the highest population and Hawassa the lowest*/
SELECT /*These case statements create columns for each type of source.
The results are aggregated per province and percentages are calculated for each province*/
ct.province_name,
ROUND((SUM(CASE WHEN source_type = 'river'
				THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
				THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
				THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
				THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
				THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt 
ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;-- Shared taps account for the largest percentage in all provinces and rivers the lowest with Sokoto having the largest share of river sources

````

3. Kilimani has a high number of contaminated wells.

````SQL

SELECT province_name,
COUNT(source_type) AS contaminated_wells
FROM combined_analysis_table
WHERE source_type='well' 
AND results LIKE 'Contaminated%'
GROUP BY province_name
ORDER BY contaminated_wells DESC;-- Shows Kilimani has the highest number of contaminated wells

````

4. A project progress table is created and from it, 25,398 improvements need to be made in Maji Ndogo.

````SQL

INSERT INTO project_progress(source_id,address,town,province,source_type,Improvement)
SELECT
	water_source.source_id,
	location.address AS Address,
	location.town_name AS Town,
	location.province_name AS Province,
	water_source.type_of_water_source AS Source_type,
CASE -- To specify the type of improvement to be made
		WHEN (water_source.type_of_water_source ='well' AND results = 'Contaminated: Biological')THEN  ' Install UV filter and RO filter' 
		WHEN ( water_source.type_of_water_source='well' AND results = 'Contaminated: Chemical') THEN 'Install RO filter'
		WHEN water_source.type_of_water_source='river' THEN 'Drill Well' 
		WHEN water_source.type_of_water_source= 'tap_in_home_broken' THEN 'Diagnose local infrastructure' 
		WHEN (water_source.type_of_water_source= 'shared_tap' AND visits.time_in_queue>=30) THEN CONCAT("Install ", FLOOR(visits.time_in_queue/30), " taps nearby")
		ELSE NULL
	  END AS Improvement
FROM
water_source
LEFT JOIN
well_pollution 
ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits 
ON water_source.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1 
AND ( well_pollution.results != 'Clean'
OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue>=30)
		);
SELECT * FROM project_progress;--Gives 25398 records

````
5. Of a total of 25,398 water sources that need attention, 12467 are wells, 5856 are broken taps in homes, 3696 are shared taps and 3379 are river sources.

````SQL

SELECT source_type,
COUNT(source_type) AS count_of_repairs
FROM project_progress
GROUP BY source_type
ORDER BY count_of_repairs DESC;
````
 
6. Kilimani has the highest number of improvements to be done while Amanzi has the least.

````SQL

SELECT province,
COUNT(Improvement) AS Improvements 
FROM project_progress
GROUP BY province
ORDER BY Improvements DESC;

````

### **RECOMMENDATION** 

1. For communities using rivers, trucks can be dispatched to those regions to provide water temporarily in the short term, while crews are sent out to drill for wells, providing a more permanent solution. Sokoto has the largest population using river sources so it should be prioritized.
2. For communities using wells, filters can be installed to purify the water. For wells with biological contamination, UV filters can be used to kill microorganisms, and for polluted wells, reverse osmosis filters. In the long term, the causes of pollution need to be determined. Kilimani is the province that has the highest number of contaminated wells so filter installation should begin there.
3. For shared taps, in the short term, additional water tankers can be sent to the busiest taps, on the busiest days. The queue time can be used to send tankers at the busiest times. Meanwhile, the work of installing extra taps where they are needed can begin. Towns like Bello, Abidjan, and Zuri have a lot of people using shared taps, so repair teams should be sent to those towns first.
4. Shared taps with short queue times (< 30 min) represent a logistical challenge to further reduce waiting times. The most effective solution, installing taps in homes, is resource-intensive and better suited as a long-term goal. According to UN standards, the maximum acceptable wait time for water is 30 minutes. With this in mind, the aim is to install taps to get queue times below 30 min. 
5. Addressing broken infrastructure offers a significant impact even with just a single intervention. It is expensive to fix, but so many people can benefit from repairing one facility. We will have to find the commonly affected areas though to see where the problem is. Amanzi province seems to be a good place to start.
6. Employees engaging in corrupt practices cannot be relied upon to produce accurate results and therefore a crackdown on corrupt officials in the water agency should be done.




