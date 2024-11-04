-- CREATE NEW AUDITOR REPORT TABLE AND IMPORT DATA FROM CSV FILE INTO IT
DROP TABLE IF EXISTS auditor_report;
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

-- QUALITY CHECK COMPARING SOURCES FROM AUDITOR REPORT AND WATER SOURCE- THEY MATCH--

SELECT  
	auditor_report.location_id AS location_id,
	auditor_report.type_of_water_source AS auditor_source,
    water_source.type_of_water_source AS surveyor_source,
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
JOIN
water_source
ON auditor_report.type_of_water_source=water_source.type_of_water_source;

-- INCLUDING ASSIGNED EMPLOYEE ID TO QUERY WHO WAS RESPONSIBLE FOR MISMATCHED RECORDS--
SELECT  
	auditor_report.location_id AS location_id,
    visits.record_id AS record_id,
    visits.assigned_employee_id,
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

-- SUBSTITUTING EMPLOYEE IDS WITH EMPLOYEE NAMES AND ADDING AUDITOR_REPORT STATEMENTS TO CREATE A VIEW --

CREATE VIEW Incorrect_records AS(
SELECT  
	auditor_report.location_id AS location_id,
	visits.record_id AS record_id,
	employee.employee_name,
	auditor_report.true_water_source_score AS auditor_score,
	water_quality.subjective_quality_score AS surveyor_score,
    auditor_report.statements
FROM auditor_report 
JOIN
	visits 
	ON auditor_report.location_id=visits.location_id
JOIN 
	water_quality
	ON visits.record_id=water_quality.record_id
JOIN
	employee
ON visits.assigned_employee_id=employee.assigned_employee_id
WHERE visits.visit_count=1 
	AND auditor_report.true_water_source_score!=water_quality.subjective_quality_score);
SELECT * FROM incorrect_records;

-- CREATING A CTE OF INCORRECT RECORDS

WITH Incorrect_records AS ( -- This brings up all records where auditor_score!=surveyor score hence incorrect--
							SELECT  
								auditor_report.location_id AS location_id,
								visits.record_id AS record_id,
								employee.employee_name,
								auditor_report.true_water_source_score AS auditor_score,
								water_quality.subjective_quality_score AS surveyor_score,
								auditor_report.statements
							FROM auditor_report 
							JOIN
								visits 
								ON auditor_report.location_id=visits.location_id
							JOIN 
								water_quality
								ON visits.record_id=water_quality.record_id
							JOIN
								employee
							ON visits.assigned_employee_id=employee.assigned_employee_id
							WHERE visits.visit_count=1 
								AND auditor_report.true_water_source_score!=water_quality.subjective_quality_score
							)
SELECT * FROM Incorrect_records;
    
 -- CREATING A CTE OF ERROR_COUNT 
   WITH error_count AS(-- This is a count of all mistakes per employee  
						SELECT  
							employee.employee_name,
							COUNT(employee.employee_name) as number_of_mistakes
						FROM auditor_report 
						JOIN
							visits 
						ON auditor_report.location_id=visits.location_id
						JOIN 
							water_quality
						ON visits.record_id=water_quality.record_id
						JOIN
							employee
						ON visits.assigned_employee_id=employee.assigned_employee_id
						WHERE visits.visit_count=1 
							AND auditor_report.true_water_source_score<water_quality.subjective_quality_score
						GROUP BY employee.employee_name
						ORDER BY COUNT(employee.employee_name) DESC)
SELECT * FROM error_count; -- 17 employees with a count of their mistakes
 
 -- ALL EMPLOYEES WITH AN ERROR COUNT ABOVE AVERAGE
   
WITH error_count AS(-- This is a count of all mistakes per employee 
					SELECT  
						employee.employee_name,
						COUNT(employee.employee_name) as number_of_mistakes
					FROM auditor_report 
					JOIN
						visits 
					ON auditor_report.location_id=visits.location_id
					JOIN 
						water_quality
					ON visits.record_id=water_quality.record_id
					JOIN
						employee
					ON visits.assigned_employee_id=employee.assigned_employee_id
					WHERE visits.visit_count=1 
						AND auditor_report.true_water_source_score<water_quality.subjective_quality_score
					GROUP BY employee.employee_name
					ORDER BY COUNT(employee.employee_name) DESC
                    )
SELECT-- This query returns a list of employee names whose mistakes are above the average
	employee_name,
	number_of_mistakes
FROM
	error_count
WHERE
	number_of_mistakes > (SELECT
						  AVG(number_of_mistakes) AS avg_error_count_per_empl
						  FROM error_count); -- This brings up 4 employees whose number of mistakes is above average
                          
                          
-- CREATING NESTED CTES PROGRESSIVELY TO FILTER OUT STATEMENTS AGAINST EMPLOYEES WITH AN ABOVE AVERAGE COUNT OF MISTAKES.

 WITH error_count AS (-- This brings up the count of all employees and their mistakes--
					SELECT  
						employee_name,
						COUNT(employee_name) as number_of_mistakes
					FROM incorrect_records
					GROUP BY employee_name
                    ),
                    -- This returns a scalar value that is the average of the errors made by employees
Avg_error_count AS(
					SELECT  
					AVG(number_of_mistakes) AS avg_error_count_per_empl
					FROM error_count
				   ),
                   -- This returns the four names of employees whose count of mistakes is higher than the average
Suspect_list AS (
				SELECT employee_name,
						number_of_mistakes
				FROM error_count
				WHERE number_of_mistakes> (SELECT  
						   AVG(number_of_mistakes)
						   FROM error_count)
				)
                 -- (EXTRACT)Extracts names,locations and statement from the incorrect_records view of the four employees above named
SELECT 
DISTINCT employee_name,
		 location_id,
		 statements
FROM incorrect_records
WHERE employee_name  IN (SELECT employee_name FROM Suspect_list );

/*SELECT -- SUBSTITUTE THIS QUERY ABOVE(EXTRACT) TO CHECK IF THERE ARE ANY OTHER EMPLOYEES WITH CASH MENTIONED IN STATEMENT
DISTINCT	employee_name
FROM incorrect_records
WHERE statements LIKE '%cash%' 
	AND employee_name  IN((SELECT employee_name
						   FROM error_count
						   WHERE number_of_mistakes> (SELECT  
													  AVG(number_of_mistakes) AS avg_error_count_per_empl
													  FROM error_count)))
													  ORDER BY employee_name;*/




