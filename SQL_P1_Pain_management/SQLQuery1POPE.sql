USE pope;
GO
SELECT * FROM pope7;
GO
ALTER TABLE pope7
ALTER COLUMN initial NVARCHAR(100);

--  DUPLICATE PID --

SELECT  PID, COUNT(PID) AS count, note
FROM pope7 
WHERE Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY  PID , note
HAVING COUNT(PID) > 1;
GO

-- Remove duplicate based on note--
DELETE Pope7
WHERE ID IN (3827, 4198, 4475);
GO

UPDATE Pope7
SET PROM = NULL
WHERE PROM = 'na' OR prom = 'n/a';
GO

ALTER TABLE pope7
ALTER COLUMN prom int;
GO
DELETE 
FROM pope7
WHERE PID ='Trần Thị Thanh Mai';
GO

UPDATE pope7
SET Pain = 'No'
WHERE ( pain = 'no' AND VAS_max <=3 AND VAS_max IS NOT NULL );
GO

UPDATE pope7
SET pain = 'yes'
WHERE (rebound = 'yes' AND VAS_rest >3 AND VAS_rest IS NOT NULL);
GO

SELECT pid, pain, vas_max, rebound, vas_rest, rescue, efficient 
FROM pope7
WHERE rescue = 'no' OR efficient = 'no';
GO

UPDATE pope7
SET rescue = 'N/a'
WHERE pain = 'no';
GO

SELECT PID, prom
FROM pope7;
GO
-- % of success --
ALTER TABLE pope7
ALTER COLUMN discharge_date DATE;
GO

SELECT site, count(*) total,
  SUM(CASE WHEN pain = 'no' THEN 1 ELSE 0 END)  success,
  SUM(CASE WHEN pain = 'yes' THEN 1 ELSE 0 END) fail

FROM pope7
WHERE Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY site;
GO
-- Not working :'|"--


CREATE VIEW pain_free_surgery AS
SELECT site, 
CAST(((CAST (SUM(CASE WHEN pain = 'no' THEN 1 ELSE 0 END) AS NUMERIC(5,2))/count(*))) AS NUMERIC(5,2)) AS "%_no_pain",
CAST((1 - (CAST (SUM(CASE WHEN pain = 'no' THEN 1 ELSE 0 END) AS NUMERIC(5,2))/count(*))) AS NUMERIC(5,2)) AS "%_pain"
FROM Pope7
WHERE Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY site;
GO

SELECT site, CAST (SUM(CASE WHEN pain = 'no' THEN 1 ELSE 0 END) AS NUMERIC(10,0)) success, COUNT(*) total
FROM pope7
WHERE Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY Site;
GO

-- MAX VAS 
--Solution for CI 95%? --

ALTER TABLE pope7
ALTER COLUMN VAS_max INT;
GO

SELECT site, MIN(VAS_max) min, AVG (VAS_max) average, MAX (VAS_max) max
FROM pope7
WHERE Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY site;
GO

-- VMPQ didn't have any case with VAS > 3 --
GO

-- % of efficient rescue --

CREATE VIEW efficient_rescue AS
SELECT site, 
       SUM(CASE WHEN Efficient = 'Yes' THEN 1 ELSE 0 END)/count(*) AS "%_success_rescue"
FROM pope7
WHERE  Efficient != 'N/A' OR Efficient IS NOT NULL 
     AND Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY site
GO

-- PREM --
CREATE VIEW prem AS
SELECT site, MIN(PREM) min, AVG (prem) average, MAX (prem) max
FROM pope7
WHERE Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY site;
GO

-- PROM --

CREATE VIEW prom AS
SELECT site, MIN(PROM) min, AVG (prom) average, MAX (prom) max
FROM pope7
WHERE Discharge_date BETWEEN '2024-07-16' AND '2024-08-16'
GROUP BY site;