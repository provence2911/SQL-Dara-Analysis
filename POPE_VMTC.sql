

UPDATE Surgery
SET Method_of_Surgery = 'surgery'
WHERE Method_of_Surgery IS NULL;
GO

SELECT*
FROM Surgery;
GO

DELETE FROM Surgery
WHERE PID IS NULL;
GO

ALTER TABLE surgery
DROP COLUMN MAX_VAS;
GO


SELECT PID, VAS_max, Type_of_rescue, Efficient_within_1h,
CASE
      WHEN Type_of_Rescue IS  NOT NULL THEN 'yes' ELSE 'no' END as 'rescue?'
FROM Surgery
WHERE VAS_max >4;
GO



SELECT *
FROM Surgery;
GO


EXEC sp_rename 'surgery.Method_of_surgery',  'Category', 'COLUMN';
Go

-- Pain free surgery
DROP VIEW IF EXISTS pain_free;

CREATE VIEW pain_free AS
SELECT month(Day_of_Surgery) as month_number   ,FORMAT(day_of_surgery,'MMM') as month, count(*) as total_case,
SUM(CASE WHEN VAS_max <= 3 OR VAS_max IS NULL THEN 1 ELSE 0 END) AS 'success_case',
SUM(CASE WHEN VAS_max > 3 THEN 1 ELSE 0 END) AS 'failure'
FROM surgery
GROUP BY month(Day_of_Surgery), FORMAT(day_of_surgery,'MMM');
GO

-- Efficent rescue within 1 h per month
DROP VIEW IF EXISTS "efficient_rescue";

CREATE VIEW efficient_rescue AS
SELECT month(Day_of_Surgery) as month_number, FORMAT(day_of_surgery,'MMM') as month,  count(*) as total_case,
SUM(CASE WHEN Efficient_within_1h = 1 THEN 1 ELSE 0 END) as num_success,
count(*) - SUM(CASE WHEN Efficient_within_1h = 1 THEN 1 ELSE 0 END) as num_failure
FROM Surgery
WHERE Efficient_within_1h IS NOT NULL 
GROUP BY month(Day_of_Surgery), FORMAT(day_of_surgery,'MMM')
GO

-- Successful rate per type of analgesia

SELECT *
FROM Surgery
GO

DROP VIEW IF EXISTS success_rate_analgesia_type;

CREATE VIEW success_rate_analgesia_type AS
WITH type_of_analgesia AS
(SELECT PID, day_of_surgery, RA_catheter, RA_singleshot,
CASE WHEN RA_catheter IS NULL AND RA_singleshot IS NOT NULL THEN 'single shot' 
     WHEN RA_catheter IS NOT NULL AND RA_singleshot IS NULL THEN 'catheter'
	 WHEN RA_catheter IS NULL AND RA_singleshot IS NULL THEN 'none' 
	 ELSE 'both' END as Analgesia_type,
CASE WHEN VAS_max <= 3 OR VAS_max IS NULL THEN 1 ELSE 0 END AS 'success_case'
FROM surgery)

SELECT month(Day_of_Surgery) as month_number, FORMAT(day_of_surgery,'MMM') as month, Analgesia_type,
      count(*) as total,
	  SUM(success_case) as total_success,
	  COUNT(*) - SUM(success_case)  as total_failure
FROM type_of_analgesia
GROUP BY month(Day_of_Surgery), FORMAT(day_of_surgery,'MMM') , Analgesia_type
GO


-- Ratio of rescue type
DROP VIEW IF EXISTS ratio_rescue_type;

CREATE VIEW ratio_rescue_type AS

SELECT month(Day_of_Surgery) as month_number, FORMAT(day_of_surgery,'MMM') as month, Type_of_Rescue, 
       COUNT(*) as num_rescue
FROM Surgery
WHERE Type_of_Rescue IS NOT NULL
GROUP BY month(Day_of_Surgery), FORMAT(day_of_surgery,'MMM'), Type_of_Rescue;
GO

UPDATE  surgery
SET VAS_max = NULL
WHERE VAS_max <=3;
GO

SELECT min(VAS_max) min, avg(VAS_max), MAX(VAS_max) max
FROM surgery
GROUP BY month(Day_of_Surgery);
GO

SELECT *
FROM Surgery
WHERE QOR_15 IS NOT NULL
ORDER BY QOR_15;