SELECT TOP (10) *
FROM job_postings_fact
WHERE job_posted_date > '2023-06-01'
;

SELECT TOP (10) job_title_short as title,
        job_location as location,
        job_posted_date AT TIMEZONE 'UTC' AT TIMEZONE 'EST' as date_time
FROM job_postings_fact;

ALTER TABLE job_postings_fact
ADD job_posted_datetimeoffset AS CAST(job_posted_date AS datetimeoffset);

-- Not working

SELECT TOP (10) job_title_short as title,
        job_location as location,
        job_posted_datetimeoffset AT TIME ZONE 'SE Asia Standard Time' AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' as date_time
FROM job_postings_fact;

-- number of job by month
SELECT COUNT(job_id) as num_job,
        MONTH(job_posted_date) as "month"
FROM job_postings_fact
WHERE job_title_short = 'Data Analyst'
GROUP BY MONTH(job_posted_date)
ORDER BY 2;

SELECT COUNT(job_id) OVER (PARTITION BY MONTH(job_posted_date) ORDER BY MONTH(job_posted_date)),
    MONTH(job_posted_date)
FROM job_postings_fact;

-- Average salary by year and by hour for jobs posted after June 1, 2023. Group by job schedule type

ALTER TABLE job_postings_fact
ALTER COLUMN job_schedule_type nvarchar(max);

SELECT job_schedule_type ,
       AVG(salary_hour_avg) as avg_hour,
       AVG(salary_year_avg) as avg_year
FROM job_postings_fact
WHERE job_posted_date > '2023-06-01'
GROUP BY job_schedule_type;

-- Companies that have posted jobs offering health insurance in Q2 2023

ALTER TABLE company_dim
ALTER COLUMN name nvarchar(max);

SELECT DISTINCT p.company_id, c.name
FROM job_postings_fact p
JOIN company_dim c
ON c.company_id = p.company_id
WHERE job_posted_date BETWEEN '2023-04-01' AND '2023-06-01'
    AND job_health_insurance = 1;

-- Create 3 new tables
-- Jan 2023

DROP TABLE IF exists Jan2023;
SELECT *
INTO Jan2023
FROM job_postings_fact
WHERE job_posted_date BETWEEN '2023-01-01' AND '2023-02-01';

SELECT TOP (10) *
FROM JAN2023
ORDER BY job_posted_date DESC;

-- Feb 2023
DROP TABLE IF exists Feb2023;
SELECT *
INTO Feb2023
FROM job_postings_fact
WHERE job_posted_date BETWEEN '2023-02-01' AND '2023-03-01';
-- Mar 2023
DROP TABLE IF exists Mar2023;
SELECT *
INTO Mar2023
FROM job_postings_fact
WHERE job_posted_date BETWEEN '2023-03-01' AND '2023-04-01';

/* Label new colum:
- Remote <= Anywhere
- Local <= New York, NY 
- Otherwise, onsite */

SELECT 
        job_title_short,
        job_location,
        CASE
            WHEN job_location = 'Anywhere' THEN 'remote'
            WHEN job_location = 'New York, NY' THEN 'local'
            ELSE 'Onsite' 
            END AS work_location
FROM job_postings_fact;

WITH job_by_location AS
(SELECT 
        job_id,
        CASE
            WHEN job_location = 'Anywhere' THEN 'remote'
            WHEN job_location = 'New York, NY' THEN 'local'
            ELSE 'Onsite' 
            END AS location_category
FROM job_postings_fact
WHERE job_title_short = 'Data Analyst')

SELECT location_category, COUNT(job_id)
FROM job_by_location
GROUP BY location_category
ORDER BY 2 DESC;

-- Top 5 skills most frequently mentioned (skills name, frequency)
Solution 1:
SELECT TOP(5) t1.skill_id, t2.skills as skill_name, COUNT(t1.skill_id) as frequency
FROM skills_job_dim t1
JOIN skills_dim t2
ON t1.skill_id = t2.skill_id
GROUP BY t1.skill_id, t2.skills
ORDER BY 3 DESC;

SOLUTION 2:

SELECT skill_id, skills
FROM skills_dim
WHERE skill_id IN 
(SELECT TOP(5) skill_id
FROM skills_job_dim 
GROUP BY skill_id
ORDER BY COUNT(skill_id) DESC);

-- Top 5 skills most frequently mentioned in remote jobs (skills name, frequency)

WITH job_by_location AS
(SELECT 
        job_id,
        CASE
            WHEN job_location = 'Anywhere' THEN 'remote'
            WHEN job_location = 'New York, NY' THEN 'local'
            ELSE 'Onsite' 
            END AS location_category
FROM job_postings_fact
),

remote_job AS
(
SELECT job_id
FROM job_by_location
WHERE location_category = 'remote')

SELECT TOP 5 skills_job_dim.skill_id, skills_dim.skills as skill_name, count(skills_job_dim.skill_id) as frequency
FROM remote_job r
JOIN skills_job_dim
ON r.job_id = skills_job_dim.job_id
JOIN skills_dim
ON skills_dim.skill_id = skills_job_dim.skill_id
GROUP BY skills_job_dim.skill_id, skills_dim.skills
ORDER BY 3 DESC;

/* Small: 10
Medium: 10 - 50
Large: 50
Based on total job postings*/
Solution 1:
SELECT sub.company_id, company_dim.name, sub.total_job_postings, sub.company_scale
FROM (
SELECT 
        company_id, 
        count(job_id) as total_job_postings,
        CASE
            WHEN count(job_id) <10 THEN 'Small'
            WHEN count(job_id) BETWEEN 10 AND 50 THEN 'Medium'
            ELSE 'Large'
            END AS company_scale
FROM job_postings_fact
GROUP BY company_id) sub
JOIN company_dim
ON company_dim.company_id = sub.company_id;

Solution 2:
WITH sub AS (
SELECT 
        company_id, 
        count(job_id) as total_job_postings,
        CASE
            WHEN count(job_id) <10 THEN 'Small'
            WHEN count(job_id) BETWEEN 10 AND 50 THEN 'Medium'
            ELSE 'Large'
            END AS company_scale
FROM job_postings_fact
GROUP BY company_id)

SELECT sub.company_id, company_dim.name, sub.total_job_postings, sub.company_scale
FROM sub
JOIN company_dim
ON company_dim.company_id = sub.company_id;

-- UNION

SELECT 
        job_title_short,
        company_id,
        job_location
FROM JAN2023

UNION

SELECT 
        job_title_short,
        company_id,
        job_location
FROM Feb2023

