/*Join water source,visits and location table excluding where sources were visited more than once.
This gives a list of all unique water sources in all provinces and towns*/

SELECT
	loc.province_name,
    loc.town_name,
    loc.location_type,
    wats.type_of_water_source,
    wats.number_of_people_served,
    vis.time_in_queue
FROM location AS loc
JOIN 
visits AS vis
ON loc.location_id=vis.location_id
JOIN
water_source AS wats
ON vis.source_id=wats.source_id
WHERE vis.visit_count = 1;

/*Join water source,location,visits and well pollution and save it as a view
This is a list of sources including pollution results for wells*/
CREATE VIEW combined_analysis_table AS (SELECT
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
										location 
                                        ON location.location_id = visits.location_id
										INNER JOIN
										water_source
										ON water_source.source_id = visits.source_id
										WHERE
										visits.visit_count = 1);
	SELECT location_type,
    COUNT(location_type) AS count_of_repairs
    FROM combined_analysis_table
    GROUP BY location_type
    ORDER BY count_of_repairs DESC;-- Most sources are in rural areas(23740).Urban(15910)
    
    SELECT province_name,
    COUNT(source_type) AS contaminated_wells
    FROM combined_analysis_table
    WHERE source_type='well' 
    AND results LIKE 'Contaminated%'
    GROUP BY province_name
    ORDER BY contaminated_wells DESC;-- Shows Kilimani has the highest number of contaminated wells
    
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
                        ORDER BY total_ppl_serv DESC;),you get a table of province names and summed up populations for each province
                        Kilimani has the highest population and Hawassa the lowest*/
SELECT /*These case statements create columns for each type of source.
The results are aggregated per province and percentages calculated for each province*/
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
-- TOWN TOTALS CTE
WITH town_totals AS (-- This CTE calculates the population of each town
					SELECT 
						province_name,
						town_name, 
					SUM(people_served) AS total_ppl_serv
					FROM combined_analysis_table
					GROUP BY province_name,town_name
                    ) -- SELECT * FROM town_totals ORDER BY total_ppl_serv DESC; -- (To get total poulation per town);
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt
ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- Group by province first, then by town to avoid grouping towns with similar names into one record.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- CREATING A TEMPORARY TABLE
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (-- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
					SELECT 
                    province_name,
                    town_name,
                    SUM(people_served) AS total_ppl_serv
					FROM combined_analysis_table
					GROUP BY province_name,town_name
                    )
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
				THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
				THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
				THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'well'
				THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well,
ROUND((SUM(CASE WHEN source_type = 'river'
				THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt 
ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- Group by province first, then by town to avoid grouping towns with similar names into one record.
ct.province_name,
ct.town_name
ORDER BY
ct.province_name;

-- TO QUERY TEMPORARY TABLE (town_aggregated_water_access) above Gives percentage of per source per town.
SELECT * FROM town_aggregated_water_access;-- Amanzi has the highest number of broken taps in homes

SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *100,0) AS Pct_broken_taps
FROM town_aggregated_water_access
ORDER BY Pct_broken_taps DESC;-- Amina in Amanzi has the highest number of broken taps in homes

-- CREATE A TABLE TO TRACK PROGRESS

CREATE TABLE Project_progress (
								Project_id SERIAL PRIMARY KEY,
								source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
								Address VARCHAR(50), 
								Town VARCHAR(30),
								Province VARCHAR(30),
								Source_type VARCHAR(50),
								Improvement VARCHAR(50), -- What the engineers should do at that place
								Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
								Date_of_completion DATE, 
								Comments TEXT
								);

/*PROJECT PROGRESS QUERY
1. Only records with visit_count = 1 are allowed(unique).
2. Any of the following rows can be included:
a. Where shared taps have queue times over 30 min.
b. Only wells that are contaminated are allowed -- So we exclude wells that are Clean
c. Include any river and tap_in_home_broken sources.*/
/*Use some control flow logic to create Install UV filter or Install RO filter values in 
the Improvement column where the results of the pollution tests were Contaminated: Biological and Contaminated: Chemical respectively. 
Use ELSE NULL for the final alternative*/

INSERT INTO project_progress(source_id,address,town,province,source_type,Improvement)
SELECT
	water_source.source_id,
	location.address AS Address,
	location.town_name AS Town,
	location.province_name AS Province,
	water_source.type_of_water_source AS Source_type,
	CASE
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
	OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
	OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue>=30)
		);
        
SELECT province,
COUNT(Improvement) AS Improvements 
FROM project_progress
GROUP BY province
ORDER BY Improvements DESC;-- Kilimani has the highest number of improvemnts and Amanzi has the lowest.
      
SELECT source_type,
COUNT(source_type) AS count_of_repairs
FROM project_progress
GROUP BY source_type
ORDER BY count_of_repairs DESC;-- The number of improvemts per type of water source

      
      
      
      
      



