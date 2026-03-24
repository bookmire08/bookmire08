-- This SQL file is the core queries and statements used to build, compile and analyze a database of 2024 monthly use data from a bikeshare service
-- The queries and statements specific to each month were repeated for the latter months and separated into individual files
-- This file presents the upload, cleaning and exploration of January's data, as well as the compilation and creation of annual summary statistics

-- SECTION START — DATA UPLOAD AND DATA CLEANING
-- Creation and upload of January 2024's data
DROP TABLE IF EXISTS 202401_divvy_tripdata

-- Due to the structure of the CSV double quotes were present in every entry in addition to the commas which separated the values.
-- This necessitated creating the table with all fields initially set to varchars

CREATE TABLE 202401_divvy_tripdata (
	ride_id VARCHAR(255),
    rideable_type VARCHAR(255),
    started_at VARCHAR(255),
    ended_at VARCHAR(255),
    start_station_name VARCHAR(255),
    start_station_id VARCHAR(255),
    end_station_name VARCHAR(255),
    end_station_id VARCHAR(255),
    start_lat VARCHAR(255),
    start_lng VARCHAR(255),
    end_lat VARCHAR(255),
    end_lng VARCHAR(255),
    member_casual VARCHAR(255) 
    );

-- The data was downloaded from the FTP server hosting it online and uploaded via the load data infile command
-- The first line contained the column names and was ignored for import
 
LOAD DATA INFILE '202401-divvy-tripdata.csv' INTO TABLE 202401_divvy_tripdata
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

-- Explored uploaded data and confirmed uploading occured without error
SELECT *
FROM 202401_divvy_tripdata
LIMIT 10;

-- Importing the data into the proper schema and data types consistently threw improper formatting or data truncated errors for the end_lat fields
-- This was confirmed when attempting to directly cast those text fields as DOUBLE or FLOAT datatypes

SELECT CAST(start_lat as DOUBLE), 
CAST(start_lng as DOUBLE), 
CAST(end_lat as DOUBLE),
CAST(end_lng as DOUBLE)
FROM 202401_divvy_tripdata;

-- Every entry uploaded into the database contained double quotes around the column entries
-- I tested using replace function to remove double quotes
SELECT REPLACE(started_at, '"', '') AS cleaned_start
FROM 202401_divvy_tripdata
LIMIT 10;

-- Clean Double Quotes from infile loaded data
-- I cleaned each column of double quotes individually
UPDATE 202401_divvy_tripdata
SET started_at = REPLACE(started_at, '"', '');

UPDATE 202401_divvy_tripdata
SET ended_at = REPLACE(ended_at, '"', '');

UPDATE 202401_divvy_tripdata
SET ride_id = REPLACE(ride_id, '"', '');

UPDATE 202401_divvy_tripdata
SET rideable_type = REPLACE(rideable_type, '"', '');

UPDATE 202401_divvy_tripdata
SET start_station_name = REPLACE(start_station_name, '"', '');

UPDATE 202401_divvy_tripdata
SET start_station_id = REPLACE(start_station_id, '"', '');

UPDATE 202401_divvy_tripdata
SET end_station_name = REPLACE(end_station_name, '"', '');

UPDATE 202401_divvy_tripdata
SET end_station_id = REPLACE(end_station_id, '"', '');

UPDATE 202401_divvy_tripdata
SET member_casual = REPLACE(member_casual, '"', '');

-- After cleaning the double quotes from all of the entries I could now properly format the columns to be the appropriate data type for analysis
-- Running these alter operations

ALTER TABLE 202401_divvy_tripdata
MODIFY started_at DATETIME;

ALTER TABLE 202401_divvy_tripdata
MODIFY ended_at DATETIME;

ALTER TABLE 202401_divvy_tripdata
MODIFY start_lat DOUBLE;

ALTER TABLE 202401_divvy_tripdata
MODIFY start_lng DOUBLE;

-- These alter statements failed due to a data truncation error at the first row no data was contained in this column
ALTER TABLE 202401_divvy_tripdata
MODIFY end_lat DOUBLE;
alter table 202401_divvy_tripdata
MODIFY end_lng DOUBLE;

-- Examining the failure point to figure out why alter table won't run
SELECT *
FROM 202401_divvy_tripdata
LIMIT 10 OFFSET 1493;
-- Columns contains empty values for nullable field
-- Test setting them as NULL

-- Setting all empty end_lat values as NULL 
UPDATE 202401_divvy_tripdata
SET end_lat = NULL
WHERE end_lat ='';

-- setting all empty end_lng values as NULL 
UPDATE 202401_divvy_tripdata
SET end_lng = NULL
WHERE end_lng ='';

-- rerunning alter table to adjust to appropriate datatype
ALTER TABLE 202401_divvy_tripdata
MODIFY end_lng DOUBLE;

ALTER TABLE 202401_divvy_tripdata
MODIFY end_lat DOUBLE;
-- Altering the end_lat and end_lng columns functioned properly after setting any blank entry as null

-- Confirming data updates, schema updates and alter functions resulted in clean data
SELECT *
FROM 202401_divvy_tripdata;
-- Cleaned data confirmed
-- This process was repeated for months February-December in separate files as to reduce the chance of user error due to lengthy sql files
-- For ease of review these files are omitted from this porfolio project 

-- SECTION END — DATA UPLOAD AND DATA CLEANING

-- NEXT SECTION — DATA EXPLORATION

-- In order to properly explore the data I verified that the timestampdiff function would run properly on the cleaned data
-- Test duration function
SELECT started_at, ended_at, timestampdiff(second, started_at, ended_at) as duration
FROM 202401_divvy_tripdata;

-- After verifying the duration calculations were accurate I created a new column within the table called duration
-- Create trip length column as duration
ALTER TABLE 202401_divvy_tripdata
ADD COLUMN duration INT NOT NULL AFTER ended_at;

-- Fill trip length column with data 
UPDATE 202401_divvy_tripdata
SET duration = timestampdiff(second, started_at, ended_at)
WHERE duration = '';

-- Finding longest trip duration 
SELECT MAX(duration)
FROM 202401_divvy_tripdata
ORDER BY started_at;
-- Longest trip duration was 89997 seconds, or over 24 hours
-- This is something I would flag for the policy makers or engineers to look at

-- The longest trips from January 2024
SELECT *
FROM 202401_divvy_tripdata
WHERE duration = 89997
ORDER BY started_at; 
-- There was more than one incident of a bicycle being rented out for over 24 hours

-- Next was to figure out the average length of rides overall
-- Finding the Average length of ride (903.4430)
SELECT AVG(duration)
FROM 202401_divvy_tripdata;

-- The next step was to figure out how many rides occurred in the month of data I was examining
-- Counting All Trips
SELECT COUNT(ride_id)
FROM 202401_divvy_tripdata;

-- This query intended to count ALL member trips for the month returned 0 rows
SELECT count(ride_id)
FROM 202401_divvy_tripdata
WHERE member_casual = 'member';
-- This query returns 0 Rows

-- I attempted to validate that this wasn't failing due to leading or trailing spaces
UPDATE 202401_divvy_tripdata
SET member_casual = TRIM(member_casual);
-- 0 rows affected, 0 rows changed
-- There was no need to trim any extra spaces from the member_casual column 

-- After researching I found that the structure for this with the best chance at capturing all results was to use the LIKE and wildcard operators in conjunction
SELECT count(ride_id)
FROM 202401_divvy_tripdata
WHERE member_casual LIKE '%member%';
-- This query ran successfuly and returned a count of 120,413

-- Finding ALL casual trips
SELECT *
FROM 202401_divvy_tripdata
WHERE member_casual = 'casual';
-- Similar to the previous attempt to find all member trips this query returns 0 Rows

-- The properly structured query behaved as expected however
SELECT count(ride_id)
FROM 202401_divvy_tripdata
WHERE member_casual LIKE '%casual%';
-- This query returned a count of 24460

-- In order to better understand the difference between member and casual rides I found the mean ride length for each category
-- Finding the Average length of ride for members, casuals and overall
-- I wrote two different queries just in case and found that either one worked as expected
SELECT AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END) AS member_avg_duration,
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END) AS casual_avg_duration
FROM 202401_divvy_tripdata;

SELECT avg(duration),
AVG(IF(member_casual LIKE '%member%', duration, NULL)) AS member_avg_duration,
AVG(IF(member_casual LIKE '%casual%', duration, NULL)) AS casual_avg_duration
FROM 202401_divvy_tripdata;
-- member_avg = 827.3177, casual_avg = 1278.1966, avg = 903.4430 — VERIFIED

SELECT *
FROM 202401_divvy_tripdata;

-- Casual Rides PER LOCATION METRICS v1
-- Retrieves casual user ride count per location
-- Orders by location popularity
SELECT start_station_name, 
start_lat,
start_lng,
count(ride_id) AS RidesPerLoc
FROM 202401_divvy_tripdata
WHERE member_casual LIKE '%casual%'
GROUP BY start_station_name, start_lat, start_lng
ORDER BY RidesPerLoc DESC;

-- Member Rides PER LOCATION METRICS v1
-- Retrieves member ride count per location
-- Orders by location popularity
SELECT start_station_name, 
start_lat,
start_lng,
count(ride_id) AS RidesPerLoc
FROM 202401_divvy_tripdata
WHERE member_casual LIKE '%member%'
GROUP BY start_station_name, start_lat, start_lng
ORDER BY RidesPerLoc DESC;

-- Rides PER start_station name METRICS v2 
-- IF just station name results are desired to find most popular location rides begin at
-- WARNINGS
-- 1. Groups different locations together when no start_station_name
-- 2. Doesn't separate Member and Casual ride count
Select start_station_name, 
count(ride_id) as RidesPerLoc
FROM 202401_divvy_tripdata
GROUP BY start_station_name
ORDER BY RidesPerLoc DESC;

-- Rides PER start_station name METRICS v3 
-- IF just station name results are desired
-- Separates member and casual ride count
Select start_station_name,
member_casual, 
count(ride_id) as RidesPerLoc
FROM 202401_divvy_tripdata
GROUP BY start_station_name, member_casual
ORDER BY start_station_name ASC;

-- In order to examine the popularity of the different types of bikes available we counted the trips taken by bicycle AND membership status

-- Finding the number of casual rides on classic bikes 
SELECT 
count(ride_id)
FROM 202401_divvy_tripdata
WHERE rideable_type like '%classic_bike%'
AND member_casual LIKE '%casual%';

-- Finding the number of member rides on classic bikes
SELECT 
count(ride_id)
FROM 202401_divvy_tripdata
WHERE rideable_type like '%classic_bike%'
AND member_casual LIKE '%member%';

-- Finding the number of casual rides on electric bikes 
SELECT 
count(ride_id)
FROM 202401_divvy_tripdata
WHERE rideable_type like '%electric_bike%'
AND member_casual LIKE '%casual%';

-- Finding the number of member rides on electric bikes 
SELECT 
count(ride_id)
FROM 202401_divvy_tripdata
WHERE rideable_type like '%electric_bike%'
AND member_casual LIKE '%member%';

-- I recorded the summary metrics in a Google Sheet initially to verify and track which months had been uploaded and explored 
-- This helped me keep track of where I was in the data analysis process
-- END OF DATA EXPLORATION SECTION


-- START OF CORE METRICS TABLE CREATION SECTION
-- Once this process had been completed for each month individually I returned to SQL to create an accompanying table that would hold these metrics more permanently
-- Documentation of the queries to create the core_metrics table follows

DROP TABLE IF EXISTS core_metrics;

-- I wanted to record the monthly summary statistics of Cyclistic ridership in 2024 and needed to create a new table
-- The metrics desired were the total rides, member rides, casual rides and their average durations
-- I additionally wanted to know the percentages of rides that were taken by members and casual riders however that needed to be added to the table after creation
Create Table core_metrics (
	month DATE,
    total_rides INT,
    member_rides INT,
    casual_rides INT,
    all_avg_duration FLOAT,
    member_avg_duration FLOAT,
    casual_avg_duration FLOAT
    );


-- Core Metrics for Jan 2024 - Dec 2024
-- The easiest way to compile all of the monthly data was to INSERT the data by SELECTing each months summary statistics and UNIONING the results 
INSERT INTO core_metrics(
month,
total_rides,
member_rides,
casual_rides,
all_avg_duration,
member_avg_duration,
casual_avg_duration
)
SELECT
'2024-01-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202401_divvy_tripdata
UNION ALL
SELECT
'2024-02-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202402_divvy_tripdata
UNION ALL
SELECT
'2024-03-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202403_divvy_tripdata
UNION ALL
SELECT
'2024-04-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202404_divvy_tripdata
UNION ALL
SELECT
'2024-05-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202405_divvy_tripdata
UNION ALL
SELECT
'2024-06-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202406_divvy_tripdata
UNION ALL
SELECT
'2024-07-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202407_divvy_tripdata
UNION ALL
SELECT
'2024-08-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202408_divvy_tripdata
UNION ALL
SELECT
'2024-09-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202409_divvy_tripdata
UNION ALL
SELECT
'2024-10-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202410_divvy_tripdata
UNION ALL
SELECT
'2024-11-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202411_divvy_tripdata
UNION ALL
SELECT
'2024-12-01',
COUNT(ride_id),
COUNT(CASE WHEN member_casual LIKE '%member%' THEN ride_id ELSE NULL END),
COUNT(CASE WHEN member_casual LIKE '%casual%' THEN ride_id ELSE NULL END),
AVG(duration),
AVG(CASE WHEN member_casual LIKE '%member%' THEN duration ELSE NULL END),
AVG(CASE WHEN member_casual LIKE '%casual%' THEN duration ELSE NULL END)
FROM 202412_divvy_tripdata;

-- Once the core metrics were created it was then possible to create the percentage of rides columns for members and casual riders
-- Create member percentage and casual percentage columns now that core metrics have been populated
ALTER TABLE core_metrics
ADD COLUMN member_pct FLOAT NULL AFTER member_rides,
ADD COLUMN casual_pct FLOAT NULL AFTER casual_rides
;

-- Update each month with percentage calculations now that data exists
UPDATE core_metrics
SET member_pct = (member_rides / total_rides),
	casual_pct = (casual_rides / total_rides);

-- Verify that all rows and columns are completed as expected
Select *
FROM core_metrics;

-- END OF CORE METRICS SECTION

-- 2024 Annual Tripdata Table Creation
-- In the event that further analysis was desired or needed I decided to create an annual tripdata table that compiled all twelve months of data
DROP TABLE IF EXISTS 2024_annual_tripdata;

-- Table creation with the proper datatype schema was possible as the already extent monthly tables contained pre-cleaned data
CREATE TABLE 2024_annual_tripdata (
	ride_id VARCHAR(255),
    rideable_type VARCHAR(255),
    started_at DATETIME,
    ended_at DATETIME,
    duration INT,
    start_station_name VARCHAR(255),
    start_station_id VARCHAR(255),
    end_station_name VARCHAR(255),
    end_station_id VARCHAR(255),
    start_lat DOUBLE,
    start_lng DOUBLE,
    end_lat DOUBLE,
    end_lng DOUBLE,
    member_casual VARCHAR(255) 
    );


-- Data insertions into this table still needed to be parsed out to avoid local timeouts 
INSERT INTO 2024_annual_tripdata (
	ride_id,
    rideable_type,
    started_at,
    ended_at,
    duration,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual 
    )
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual
FROM 202401_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202402_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202403_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202404_divvy_tripdata;

-- Counts of rows of data were necessary to verify the proper aggregation of data
SELECT count(ride_id)
FROM 2024_annual_tripdata;

INSERT INTO 2024_annual_tripdata (
	ride_id,
    rideable_type,
    started_at,
    ended_at,
    duration,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual 
    )
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202405_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202406_divvy_tripdata;

-- Rows were counted after each insert to verify that the imports were happening without data dropping or additional rows appearing
Select count(ride_id)
FROM 2024_annual_tripdata;

INSERT INTO 2024_annual_tripdata (
	ride_id,
    rideable_type,
    started_at,
    ended_at,
    duration,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual 
    )
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202407_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202408_divvy_tripdata;

INSERT INTO 2024_annual_tripdata (
	ride_id,
    rideable_type,
    started_at,
    ended_at,
    duration,
    start_station_name,
    start_station_id,
    end_station_name,
    end_station_id,
    start_lat,
    start_lng,
    end_lat,
    end_lng,
    member_casual 
    )
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202409_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202410_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202411_divvy_tripdata
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, duration, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual 
FROM 202412_divvy_tripdata;

-- After January - December's data was inserted into the annual data one last count was taken to verify the proper import of over 5 million rows of data
Select COUNT(ride_id)
FROM 2024_annual_tripdata;

-- One additional piece of information I wanted for the analysis was to understand the differences in average trip length
-- Casual riders on average were taking longer trips than members
-- This was expected as members were allowed to take an unlimited amount of 45 minute trips but if they wanted a longer trip had to return the bike and rent it again immediately

-- I counted each type of ride for members in these two categories, 'less than 45 minutes' and '45 minutes or longer'
SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE member_casual LIKE '%member%'
AND duration < 2700;

SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE member_casual LIKE '%member%'
AND duration >= 2700;

-- I counted each type of ride for casual riders in these two categories, 'less than 45 minutes' and '45 minutes or longer'
SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE member_casual LIKE '%casual%'
AND duration < 2700;

SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE member_casual LIKE '%casual%'
AND duration >= 2700;

-- I was then curious to see if there was a preference for type of bike, classic or electric for either longer or shorter rides
SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE rideable_type LIKE '%electric_bike%'
AND duration >= 2700;

SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE rideable_type LIKE '%classic_bike%'
AND duration >= 2700;

SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE rideable_type LIKE '%electric_bike%'
AND duration < 2700;

SELECT count(ride_id)
FROM 2024_annual_tripdata
WHERE rideable_type LIKE '%classic_bike%'
AND duration < 2700;

-- The results were that longer rides tended to happen on classic bicycles
-- For shorter rides the split between electric and classic bicycles was much closer with more riders choosing electric
-- END 2024 Annual Trip Data SECTION

-- The Core metrics as well as other interesting facets of the data exploration were saved in Google Sheets for ease of access and reporting
-- Google Sheets and Lookerstudio were used to create data visualizations and a report was written in Google docs