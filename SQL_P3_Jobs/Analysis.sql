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


-- Top 5 skills in remote jobs


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
What are the tops optimal skills?*/

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



