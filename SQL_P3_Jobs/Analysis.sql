/*
Question: What are top paying data analyst jobs?
- Identify the top 10 highest paying data analyst roles remotely?
- Focus on job posterings with specified salaries (remove NULL)
- Why? Highlight the top paying opportunities for Data analyst, offering insight into companies providing these jobs
*/

SELECT TOP(10)
        name as company_name,
        job_id,
        job_title,
        job_location,
        job_schedule_type,
        salary_year_avg,
        job_posted_date
FROM
        job_postings_fact
LEFT JOIN company_dim
ON company_dim.company_id = job_postings_fact.company_id
WHERE
        job_title_short = 'data analyst' AND job_location = 'anywhere'
        AND salary_year_avg IS NOT NULL
ORDER BY salary_year_avg DESC;


/* 
Top paying job skills required
Question: What skills are required for the top-paying remote data analyst jobs? to show what skills are in top demand
*/

WITH top_10 AS (
SELECT TOP(10)
        name as company_name,
        job_id,
        job_title,
        salary_year_avg
FROM
        job_postings_fact
LEFT JOIN company_dim
ON company_dim.company_id = job_postings_fact.company_id
WHERE
        job_title_short = 'data analyst' AND job_location = 'anywhere'
        AND salary_year_avg IS NOT NULL
ORDER BY salary_year_avg DESC
)

SELECT top_10.*,
        skills
FROM top_10
JOIN skills_job_dim sk
ON sk.job_id = top_10.job_id
JOIN skills_dim 
ON skills_dim.skill_id = sk.skill_id
ORDER BY salary_year_avg DESC;



/* Insight:
SQL is leading, then Python follows closely
Tableau is also highly sought after
Other skills like R, Snowflake, Pandas, Excel show varying degrees of demand.
*/

/* Top 5 skills most demanded (skills name, frequency)
Question: What are the most in-demand skills for Data analysts?
*/

-- Case 1: Top 5 skills in remote jobs

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

-- Case 2: Top 5 skills in all job postings

SELECT top (5) 
    skills,
    COUNT(sk.job_id) AS demand_count
FROM job_postings_fact as fact
JOIN skills_job_dim sk
ON sk.job_id = fact.job_id
JOIN skills_dim 
ON skills_dim.skill_id = sk.skill_id
WHERE job_title_short = 'Data analyst' AND job_work_from_home = 1
GROUP BY skills
ORDER BY 2 DESC


/*
What are the tops skills based on salary?
- Look at the average salary associated with each skill for Data analyst job
- Focuses on role with specified salaries, regardless of location
- Why? It reveals how different skills impact salary levels for data analyst and helps identify the most rewarding skills to acquire or improve.
*/

SELECT TOP(25)
    skills,
    ROUND(AVG(salary_year_avg),0) as avg_salary
FROM job_postings_fact as fact
JOIN skills_job_dim sk
ON sk.job_id = fact.job_id
JOIN skills_dim 
ON skills_dim.skill_id = sk.skill_id
WHERE job_title_short = 'Data analyst' AND salary_year_avg IS NOT NULL
    -- AND job_work_from_home = 1
GROUP BY skills
ORDER BY 2 DESC

/* Insight:
Here are the key insights in 3 concise bullet points:


