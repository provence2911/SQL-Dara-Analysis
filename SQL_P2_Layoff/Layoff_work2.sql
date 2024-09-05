
USE Practice;
GO

SELECT *
FROM layoffs;
GO

-- Remove duplicates


DROP TABLE IF exists layoff_work;
SELECT *
INTO layoff_work
FROM layoffs;
GO

WITH duplicate_cte AS
   (SELECT *,
    ROW_NUMBER() OVER (PARTITION BY company,location,
	industry,total_laid_off,percentage_laid_off, date,stage,
	country,funds_raised_millions ORDER BY date) as row_num
    FROM layoff_work)

SELECT *
FROM duplicate_cte
WHERE row_num >1;
GO

SELECT *
INTO layoff_work2
FROM layoff_work
WHERE 0 =1;
GO

 
ALTER TABLE layoff_work2
ADD row_num INT;
GO

 
INSERT INTO  layoff_work2
SELECT *,
    ROW_NUMBER() OVER (PARTITION BY company,location,
	industry,total_laid_off,percentage_laid_off, date,stage,
	country,funds_raised_millions ORDER BY date) as row_num
FROM layoff_work;
GO

DELETE 
FROM layoff_work2
WHERE row_num > 1;
GO

-- Standadize data

UPDATE layoff_work2
SET company = TRIM(company);
GO

UPDATE layoff_work2
SET country = 'United States'
WHERE industry LIKE 'United States%';
GO

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoff_work2;
GO

UPDATE layoff_work2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United State%';
GO

-- Populated values from existing data

SELECT t1.company, t1.industry, t2.company,  t2.industry
FROM layoff_work2 t1
JOIN layoff_work2 t2
ON t1.company = t2.company AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
GO

UPDATE  t1
SET t1.industry = t2.industry
FROM layoff_work2 t1 
JOIN layoff_work2 t2
ON t1.company = t2.company AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
GO

ALTER TABLE layoff_work2
DROP COLUMN row_num;
GO


SELECT*
FROM layoff_work2;
GO


-- Total laid off per year

DROP VIEW IF exists laid_off_year;

CREATE VIEW laid_off_year AS

SELECT year(date) as year, SUM(total_laid_off) as total
FROM layoff_work2
WHERE year(date) IS NOT NULL
GROUP BY year(date);
GO


-- Running total by month (matrix)

DROP VIEW IF exists running_total_month;

CREATE VIEW running_total_month AS

WITH monthly_out AS
(SELECT year(date) as "year", SUBSTRING(CAST(date AS varchar(20)),1,7) as "month", SUM(total_laid_off) as total
FROM layoff_work2
WHERE SUBSTRING(CAST(date AS varchar(20)),1,7) IS NOT NULL
GROUP BY year(date), SUBSTRING(CAST(date AS varchar(20)),1,7))

SELECT *,
       SUM(total) OVER (ORDER BY "month") as running_total
FROM monthly_out;
GO

-- Draft
SELECT SUBSTRING(CAST(date AS varchar(20)),1,7) as "month", SUM(total_laid_off) as total
FROM layoff_work2
WHERE SUBSTRING(CAST(date AS varchar(20)),1,7) IS NOT NULL
GROUP BY SUBSTRING(CAST(date AS varchar(20)),1,7)
ORDER BY 1;
GO




-- Top 5 countries with highest total laid off by year

SELECT year(date) as "year", company, 
       SUM(total_laid_off) as total
FROM layoff_work2
GROUP BY year(date), company
ORDER BY 3 DESC;
GO

CREATE VIEW company_year_rank AS 

WITH company_year AS
(SELECT year(date) as "year", company, 
       SUM(total_laid_off) as total
FROM layoff_work2
GROUP BY year(date), company),
     company_year_rank AS
(SELECT "year", company, total,
        DENSE_RANK() OVER (PARTITION BY "year" ORDER BY total DESC) as rank_
FROM company_year
WHERE "year" IS NOT NULL)

SELECT *
FROM company_year_rank
WHERE RANK_ <= 5;
GO

-- Top 5 industries with highest laid_off_total per year

SELECT year(date) as "year", industry, 
       SUM(total_laid_off) as total
FROM layoff_work2
GROUP BY year(date), industry
ORDER BY 3 DESC;
GO

CREATE VIEW industry_year_rank AS 

WITH industry_year AS
(SELECT year(date) as "year", industry, 
       SUM(total_laid_off) as total
FROM layoff_work2
GROUP BY year(date), industry),

     industry_year_ranking AS
(SELECT *,
       DENSE_RANK() OVER (PARTITION BY "year" ORDER BY total DESC) as ranking
FROM industry_year
WHERE "year" IS NOT NULL)

SELECT *
FROM industry_year_ranking
WHERE ranking <= 5;
GO

-- Top 5 stages having the most total_laid_off of all time
SELECT *
FROM layoff_work2
GO

SELECT stage,
       SUM(total_laid_off) as ranking
FROM layoff_work2
GROUP BY stage
ORDER BY 2 DESC;
GO

 CREATE VIEW top_5_stage AS

WITH stage_laid_off AS
(SELECT stage,
       SUM(total_laid_off) as total
FROM layoff_work2
GROUP BY stage)
SELECT TOP 5 *,
      DENSE_RANK() OVER (ORDER BY total DESC) as ranking
FROM stage_laid_off;
