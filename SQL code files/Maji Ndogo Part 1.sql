-- 1.GETTING TO KNOW OUR DATA- Bring up tables and see what each contains.
USE md_water_services;
SHOW TABLES IN md_water_services;
SELECT 
	*
FROM md_water_services.data_dictionary;
SELECT 
	*
FROM md_water_services.location
LIMIT 5;
SELECT 
	*
FROM md_water_services.visits
LIMIT 5;
SELECT 
	*
FROM md_water_services.water_source;

-- Find our microbilogist from the employee table
SELECT 
	*
FROM md_water_services.employee
WHERE position LIKE 'micro%';

-- Find employees with few details
SELECT employee_name
FROM employee
WHERE 
    (phone_number LIKE '%86%'
    OR phone_number LIKE '%11%')
    AND (employee_name LIKE '% A%' 
    OR employee_name LIKE '% M%')
    AND position = 'Field Surveyor';

-- Find the population in Maji_Ndogo by querying data dictionary
SELECT *
FROM data_dictionary WHERE description LIKE '%population%' ;
SELECT * FROM global_water_access;
SELECT 
pop_n
FROM global_water_access
WHERE name = 'Maji Ndogo';

-- 2.DIVE INTO WATER SOURCES- Distinct types of water sources
/*in the first record 160 homes nearby were combined into one record, with an average of 6 people living in each house 160 x 6 ≈ 956. So 1 tap_in_home
or tap_in_home_broken record actually refers to multiple households, with the sum of the people living in these homes equal to number_of_people_served*/
SELECT *
FROM md_water_services.water_source;

SELECT 
DISTINCT type_of_water_source
FROM md_water_services.water_source;

-- 3.UNPACK VISITS TABLE  Query fo find where people queue for more than 500 then
/*use the source_ids of the top to query the water_source table to find out their type.*/
SELECT 
	*
FROM md_water_services.visits
WHERE
	time_in_queue>500
LIMIT 10;
-- Sources vs Number of people they serve
SELECT
	source_id,
    type_of_water_source,
    number_of_people_served
FROM md_water_services.water_source
WHERE
	source_id='AkRu04862224'
    OR source_id='AkRu05603224'
    OR source_id='AmAs10911224'
    OR source_id='AkHa00036224';
    
  -- 4.ASSESS THE QUALITY OF WATER SOURCES
SELECT
	*
FROM md_water_services.water_quality;
-- Records where officials visited more than once and in places with tap water at home(SQS 0f 10)--
/*The surveyors only made multiple visits to shared taps and did not revisit other types of water sources. So
there should be no records of second visits to locations where there are good water sources, like taps in homes.*/

SELECT
	record_id,
    subjective_quality_score,
    visit_count
FROM md_water_services.water_quality
WHERE subjective_quality_score=10
	AND visit_count>=2;
   
-- 5.INVESTIGATE POLLUTION ISSUES   
-- Pulling first 5 records from well_pollution table
SELECT
	*
FROM md_water_services.well_pollution
LIMIT 5;

-- Checking biological contamination above 0.01 yet results marked clean
SELECT
	*
FROM md_water_services.well_pollution
WHERE biological>0.01
AND results='Clean';

-- Finding errors due to poorly recorded values in description column
SELECT
	*
FROM md_water_services.well_pollution
WHERE description LIKE 'Clean_%'
	AND biological>0.01;

-- Checking presence of parasites
SELECT * 
FROM well_pollution
WHERE description
	IN ('Parasite: Cryptosporidium', 'biologically contaminated')
	OR (results = 'Clean' AND biological > 0.01);

/* CREATE A TABLE WELL_POLLUTION_COPY
-- Update it and when confirmed,drop it and update the well_pollution table
CREATE TABLE
md_water_services.employee_copy
AS (
SELECT
*
FROM
md_water_services.employee
); 
SET SQL_SAFE_UPDATES=0;
-- Update well pollution copy--
UPDATE
well_pollution_copy
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';
UPDATE
well_pollution_copy
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';
UPDATE
well_pollution_copy
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean';

-- Querying if all updates were successful--
SELECT 
	*
FROM md_water_services.well_pollution_copy
WHERE 
	description LIKE 'Clean_%'
OR  (biological > 0.01 AND results = 'Clean');

-- Drop well pollution copy--
DROP table md_water_services.well_pollution_copy; */

-- UPDATE WELL_POLLUTION TABLE
SET SQL_SAFE_UPDATES=0;
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
SELECT 
	*
FROM md_water_services.well_pollution
WHERE 
	description LIKE 'Clean_%'
	OR  (biological > 0.01 AND results = 'Clean');

-- Returns all clean well sources
SELECT *
FROM well_pollution
WHERE description LIKE 'Clean_%' OR results = 'Clean' AND biological < 0.01;
