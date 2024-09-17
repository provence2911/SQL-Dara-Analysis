
USE Practice;
GO
SELECT *
FROM po1
ORDER BY date_of_surgery;
GO

ALTER TABLE po1
DROP COLUMN Discharge_day;
GO

-- Delete row with NULL VALUE  
DELETE 
FROM po1
WHERE PID IS NULL OR Day_of_Surgery IS NULL;
GO

-- Rename columns for easier reading 
EXEC sp_rename 'po1.method_of_surgery',  'type_of_surgery', 'COLUMN';
GO

EXEC sp_rename 'po1.day_of_surgery',  'date_of_surgery', 'COLUMN';
GO

EXEC sp_rename 'po1.Day_of_Pain_max',  'day_of_max_pain', 'COLUMN';
GO

EXEC sp_rename 'po1.Isomnia',  'Insomnia', 'COLUMN';
GO

-- Change values for consistent categories
UPDATE po1
SET type_of_surgery = 'C-section'
WHERE type_of_surgery = 'OB-delivery';
GO

UPDATE po1
SET type_of_surgery = 'Other surgeries'
WHERE type_of_surgery = 'Surgery';
GO

UPDATE po1
SET _1st_Standing_up = 'After D2'
WHERE _1st_Standing_up = 'Later';
GO

UPDATE po1
SET singleshot = TRIM(TRAILING ', ' FROM singleshot)
WHERE RIGHT(singleshot,2) = ', ';
GO

-- % of cases with no pain or mild pain (VAS <4)--

DROP VIEW IF exists Pain_free_surgery;

CREATE VIEW Pain_free_surgery AS
SELECT month(date_of_surgery) as Month_num ,FORMAT(date_of_surgery,'MMM') as Month,
	   COUNT(*) total,
       SUM(CASE WHEN max_vas IS NULL THEN 1 ELSE 0 END) AS 'success_case',
	   COUNT(*) - SUM(CASE WHEN max_vas IS NULL THEN 1 ELSE 0 END) as 'need_rescue'
FROM po1

GROUP BY month(date_of_surgery),FORMAT(date_of_surgery,'MMM')
GO


-- Did patient receive response from medical staff when having pain?
-- Number of successful rescue?

DROP VIEW IF exists response_to_pain;

CREATE VIEW response_to_pain AS
WITH rescue_sub AS
(SELECT month(date_of_surgery) as Month_num, FORMAT(date_of_surgery,'MMM') as "Month",  PID, max_vas, Type_of_rescue, Efficient_within_1h,
CASE
      WHEN Type_of_Rescue IS  NOT NULL THEN 1 ELSE 0 END as 'rescue_available',
CASE WHEN Type_of_Rescue IS NULL THEN 1 ELSE 0 END as 'no_rescue_given',
CASE WHEN Efficient_within_1h = 1 THEN 1 ELSE 0 END as "successful_rescue"
FROM po1
WHERE MAX_VAS > 3)

SELECT month_num, month, 
      count(max_vas) as total_pain_case,     
	  SUM(no_rescue_given) as total_no_rescue_given,
	  SUM(rescue_available) as total_rescue_done,
	  SUM(successful_rescue) as num_successful_rescue,
	  SUM(rescue_available) - SUM(successful_rescue) as num_failed_rescue
FROM rescue_sub
GROUP BY month_num, month;
GO


-- Successful rate per type of analgesia

DROP VIEW IF exists type_of_analgesia;

CREATE VIEW type_of_analgesia AS

WITH type_of_analgesia AS
(SELECT 
    PID, date_of_surgery, catheter, singleshot,
    CASE 
        WHEN catheter IS NULL AND singleshot IS NOT NULL THEN 'Single shot' 
        WHEN catheter IS NOT NULL AND singleshot IS NULL THEN 'Catheter'
	    WHEN catheter IS NULL AND singleshot IS NULL THEN 'No RA' 
	    ELSE 'Combine' END as Analgesia_type,
    CASE 
        WHEN max_vas <= 3 OR max_vas IS NULL THEN 1 ELSE 0 END AS 'success'
FROM po1)

SELECT 
    MONTH(Date_of_Surgery) as Month_num, 
    FORMAT(date_of_surgery,'MMM') as Month, Analgesia_type,
    COUNT(*) as total,
	SUM(success) as "total_success",
	COUNT(*) - SUM(success)  as "total_failure"
FROM type_of_analgesia
GROUP BY month(Date_of_Surgery), FORMAT(date_of_surgery,'MMM'),  Analgesia_type;

-- Ratio of rescue

DROP VIEW IF exists ratio_of_rescue;

CREATE VIEW ratio_of_rescue AS

SELECT month(Date_of_Surgery) as Month_num, FORMAT(Date_of_Surgery,'MMM') as Month, Type_of_Rescue, 
       COUNT(*) as num_rescue
FROM po1
WHERE Type_of_Rescue IS NOT NULL
GROUP BY month(Date_of_Surgery), FORMAT(Date_of_Surgery,'MMM'), Type_of_Rescue;
GO

-- Day when most severe pain happens

DROP VIEW IF exists day_of_max_pain;

CREATE VIEW day_of_max_pain AS
SELECT month(Date_of_Surgery) as Month_num, FORMAT(Date_of_Surgery,'MMM') as "Month", day_of_max_pain, 
COUNT(*)/(SELECT CAST( COUNT(*) AS NUMERIC(4,2))
						FROM po1
						WHERE MAX_VAS >5) as "%frequency"
FROM po1
WHERE max_vas > 5 AND Day_of_max_pain IS NOT NULL
GROUP BY month(Date_of_Surgery), FORMAT(Date_of_Surgery,'MMM'), day_of_max_pain;
Go