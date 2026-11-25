USE [RetailBank];
GO

-- ==================   DimDate ==================

DROP TABLE IF EXISTS Gold.FactTransaction;
DROP TABLE IF EXISTS Gold.DimDate;
DROP TABLE IF EXISTS Gold.DimCustomer;
DROP TABLE IF EXISTS Gold.DimMerchant;
GO

CREATE TABLE Gold.DimDate (
	datekey         INT NOT NULL PRIMARY KEY,
	full_date       DATE NOT NULL,
	[year]          INT NOT NULL,
	[quarter]       INT NOT NULL,
	[month]         INT NOT NULL,
	month_name      VARCHAR(20) NOT NULL,
	year_month      CHAR(7) NOT NULL,     
	[day]           INT NOT NULL,
	day_of_week     INT NOT NULL,           
	day_name        VARCHAR(20) NOT NULL,
	is_weekend      BIT NOT NULL
);
GO

DECLARE @start_date DATE, @end_date DATE, @current_date DATE;

SELECT
	@start_date = MIN(transaction_date),
	@end_date   = MAX(transaction_date)
FROM Silver.[transaction];

SET @current_date = @start_date;

WHILE @current_date <= @end_date
BEGIN
	INSERT INTO Gold.DimDate (
		datekey, full_date, [year], [quarter], [month], month_name, year_month,
		[day], day_of_week, day_name, is_weekend)
	VALUES (
		CAST(FORMAT(@current_date, 'yyyyMMdd') AS INT),
		@current_date,
		YEAR(@current_date),
		DATEPART(QUARTER, @current_date),
		MONTH(@current_date),
		DATENAME(MONTH, @current_date),
		FORMAT(@current_date, 'yyyy-MM'),
		DAY(@current_date),
		(DATEDIFF(DAY, '19000101', @current_date) % 7) + 1,    
		DATENAME(WEEKDAY, @current_date),
		CASE WHEN (DATEDIFF(DAY, '19000101', @current_date) % 7) + 1 IN (6, 7) THEN 1 ELSE 0 END
	);
	SET @current_date = DATEADD(DAY, 1, @current_date);
END;
GO

SELECT * FROM Gold.DimDate;
GO


-- ==================   DimCustomer ==================

DECLARE @as_of DATE = (SELECT MAX(transaction_date) FROM Silver.[transaction]);

SELECT
	c.customer_id,
	c.first_name + ' ' + c.last_name				AS full_name,
	c.first_name,
	c.last_name,
	c.gender,
	CASE c.gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE 'Unknown' END AS gender_label,
	YEAR(c.dob)										AS birth_year,
	a.age,
	CASE WHEN a.age IS NULL THEN 'Unknown'
	     WHEN a.age < 18 THEN '<18'
	     WHEN a.age < 25 THEN '18-24'
	     WHEN a.age < 35 THEN '25-34'
	     WHEN a.age < 45 THEN '35-44'
	     WHEN a.age < 55 THEN '45-54'
	     WHEN a.age < 65 THEN '55-64'
	     ELSE '65+' END								AS age_band,
	CASE WHEN a.age IS NULL THEN 99
	     WHEN a.age < 18 THEN 1 WHEN a.age < 25 THEN 2 WHEN a.age < 35 THEN 3
	     WHEN a.age < 45 THEN 4 WHEN a.age < 55 THEN 5 WHEN a.age < 65 THEN 6
	     ELSE 7 END									AS age_band_sort,
	RIGHT(c.cc_num, 4)								AS card_last4,
	c.city,
	c.state,
	c.zip,
	c.latitude,
	c.longitude,
	c.city_pop										AS city_population,
	c.job,
	c.loyalty_tier,
	CASE c.loyalty_tier WHEN 'Bronze' THEN 1 WHEN 'Silver' THEN 2 WHEN 'Gold' THEN 3 WHEN 'Platinum' THEN 4 ELSE 0 END AS loyalty_tier_sort,
	c.email_domain,
	c.signup_date,
	YEAR(c.signup_date)								AS signup_year,
	CAST(CASE WHEN a.age < 18 THEN 1 ELSE 0 END AS TINYINT) AS is_minor,
	CAST(CASE WHEN c.dq_signup_under_18 = 1 OR c.dq_signup_before_dob = 1 THEN 1 ELSE 0 END AS TINYINT) AS dq_signup_issue
INTO Gold.DimCustomer
FROM Silver.customer AS c
CROSS APPLY (
	SELECT CASE WHEN c.dob IS NULL THEN NULL
	            ELSE DATEDIFF(YEAR, c.dob, @as_of)
	                 - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, c.dob, @as_of), c.dob) > @as_of THEN 1 ELSE 0 END
	       END AS age
) AS a;

ALTER TABLE Gold.DimCustomer ALTER COLUMN customer_id INT NOT NULL;
ALTER TABLE Gold.DimCustomer ADD CONSTRAINT PK_DimCustomer PRIMARY KEY (customer_id);
GO


-- ==================   DimMerchant ==================

SELECT
	merchant_id,
	merchant_name,
	merchant_name + ' [' + CAST(merchant_id AS VARCHAR(10)) + ']' AS merchant_label,   -- unique + readable
	merchant_category,
	merchant_city,
	merchant_state,
	merchant_lat										AS merchant_latitude,
	merchant_long										AS merchant_longitude,
	merchant_since,
	YEAR(merchant_since)								AS merchant_since_year,
	CASE is_active WHEN 1 THEN 'Active' WHEN 0 THEN 'Inactive' ELSE 'Unknown' END AS active_status
INTO Gold.DimMerchant
FROM Silver.merchant;

ALTER TABLE Gold.DimMerchant ALTER COLUMN merchant_id INT NOT NULL;
ALTER TABLE Gold.DimMerchant ADD CONSTRAINT PK_DimMerchant PRIMARY KEY (merchant_id);
GO


-- ==================   FactTransaction ==================


SELECT
	transaction_id,
	CAST(FORMAT(transaction_date, 'yyyyMMdd') AS INT)	AS date_key,
	customer_id,
	merchant_id,
	transaction_datetime,
	DATEPART(HOUR, transaction_datetime)				AS transaction_hour,
	CASE WHEN DATEPART(HOUR, transaction_datetime) < 6  THEN 'Night'
	     WHEN DATEPART(HOUR, transaction_datetime) < 12 THEN 'Morning'
	     WHEN DATEPART(HOUR, transaction_datetime) < 18 THEN 'Afternoon'
	     ELSE 'Evening' END							AS time_of_day,
	CASE WHEN DATEPART(HOUR, transaction_datetime) < 6  THEN 1
	     WHEN DATEPART(HOUR, transaction_datetime) < 12 THEN 2
	     WHEN DATEPART(HOUR, transaction_datetime) < 18 THEN 3
	     ELSE 4 END									AS time_of_day_sort,
	category,
	payment_method,
	channel,
	entry_mode,
	device_type,
	transaction_status,
	currency,
	amount,
	tax_amount,
	discount_amount,
	amount - discount_amount							AS net_amount,
	CAST(CASE WHEN transaction_status = 'approved' THEN 1 ELSE 0 END AS TINYINT) AS is_approved,
	CAST(CASE WHEN transaction_status = 'declined' THEN 1 ELSE 0 END AS TINYINT) AS is_declined,
	CAST(CASE WHEN transaction_status = 'refunded' THEN 1 ELSE 0 END AS TINYINT) AS is_refunded,
	CAST(is_fraud AS TINYINT)							AS is_fraud,
	CASE WHEN is_fraud = 1 THEN 'Fraud' ELSE 'Legitimate' END AS fraud_label,
	CAST(dq_before_signup AS TINYINT)					AS is_pre_signup_txn,
	trans_num
INTO Gold.FactTransaction
FROM Silver.[transaction];

ALTER TABLE Gold.FactTransaction ALTER COLUMN transaction_id INT NOT NULL;
ALTER TABLE Gold.FactTransaction ADD CONSTRAINT PK_FactTransaction PRIMARY KEY (transaction_id);
GO


-- ==================   Foreign keys ==================

ALTER TABLE Gold.FactTransaction
	ADD CONSTRAINT FK_Fact_DimDate FOREIGN KEY (date_key)
	REFERENCES Gold.DimDate (datekey);
GO

ALTER TABLE Gold.FactTransaction
	ADD CONSTRAINT FK_Fact_DimCustomer FOREIGN KEY (customer_id)
	REFERENCES Gold.DimCustomer (customer_id);
GO

ALTER TABLE Gold.FactTransaction
	ADD CONSTRAINT FK_Fact_DimMerchant FOREIGN KEY (merchant_id)
	REFERENCES Gold.DimMerchant (merchant_id);
GO


-- ==================   Indexes ==================

CREATE INDEX IX_Fact_DateKey    ON Gold.FactTransaction (date_key);
CREATE INDEX IX_Fact_CustomerId ON Gold.FactTransaction (customer_id);
CREATE INDEX IX_Fact_MerchantId ON Gold.FactTransaction (merchant_id);
GO


-- ==================   Gold validation ==================


SELECT 'DimCustomer'      AS tbl, COUNT(*) AS total_rows FROM Gold.DimCustomer
UNION ALL SELECT 'DimMerchant',     COUNT(*) FROM Gold.DimMerchant
UNION ALL SELECT 'DimDate',         COUNT(*) FROM Gold.DimDate
UNION ALL SELECT 'FactTransaction', COUNT(*) FROM Gold.FactTransaction;

-- referential integrity 
SELECT
	(SELECT COUNT(*) FROM Gold.FactTransaction f LEFT JOIN Gold.DimDate     d ON d.datekey     = f.date_key    WHERE d.datekey     IS NULL) AS fact_without_date,
	(SELECT COUNT(*) FROM Gold.FactTransaction f LEFT JOIN Gold.DimCustomer c ON c.customer_id = f.customer_id WHERE c.customer_id IS NULL) AS fact_without_customer,
	(SELECT COUNT(*) FROM Gold.FactTransaction f LEFT JOIN Gold.DimMerchant m ON m.merchant_id = f.merchant_id WHERE m.merchant_id IS NULL) AS fact_without_merchant;

-- money reconciles Silver -> Gold 
SELECT
	(SELECT SUM(amount) FROM Silver.[transaction]) AS silver_amount,
	(SELECT SUM(amount) FROM Gold.FactTransaction) AS gold_amount;

-- key KPIs 
SELECT
	SUM(is_approved)                                       AS approved_txns,
	SUM(CASE WHEN is_approved = 1 THEN amount     END)     AS approved_gross,
	SUM(CASE WHEN is_approved = 1 THEN net_amount END)     AS approved_net,
	SUM(is_fraud)                                          AS fraud_txns
FROM Gold.FactTransaction;
GO