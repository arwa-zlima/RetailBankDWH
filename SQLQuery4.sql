USE [RetailBank];
GO

-- ==================   Silver.customer ==================

DROP TABLE IF EXISTS Silver.customer;
GO

SELECT
	TRY_CAST(customer_id AS INT)						AS customer_id,
	NULLIF(LTRIM(RTRIM(cc_num)), '')					AS cc_num,
	ISNULL(NULLIF(LTRIM(RTRIM(first_name)), ''), 'Unknown')	AS first_name,
	ISNULL(NULLIF(LTRIM(RTRIM(last_name)), ''), 'Unknown')	AS last_name,
	CASE UPPER(LEFT(LTRIM(RTRIM(ISNULL(gender, ''))), 1))
		WHEN 'F' THEN 'F'
		WHEN 'M' THEN 'M'
		ELSE 'U'
	END													AS gender,
	ISNULL(NULLIF(LTRIM(RTRIM(street)), ''), 'Unknown')	AS street,
	ISNULL(NULLIF(LTRIM(RTRIM(city)), ''), 'Unknown')	AS city,
	ISNULL(NULLIF(UPPER(LTRIM(RTRIM(state))), ''), 'Unknown') AS state,
	CASE WHEN TRY_CAST(TRY_CAST(NULLIF(LTRIM(RTRIM(zip)), '') AS DECIMAL(10,1)) AS INT) IS NULL THEN 'Unknown'
	     ELSE RIGHT('00000' + CAST(TRY_CAST(TRY_CAST(NULLIF(LTRIM(RTRIM(zip)), '') AS DECIMAL(10,1)) AS INT) AS VARCHAR(10)), 5)
	END AS zip,	TRY_CAST([lat]  AS DECIMAL(9,6))					AS latitude,
	TRY_CAST([long] AS DECIMAL(9,6))					AS longitude,
	TRY_CAST(city_pop AS INT)							AS city_pop,
	ISNULL(NULLIF(LTRIM(RTRIM(job)), ''), 'Unknown')	AS job,
	TRY_CAST(dob AS DATE)								AS dob,
	ISNULL(NULLIF(LTRIM(RTRIM(loyalty_tier)), ''), 'Unassigned') AS loyalty_tier,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(email_domain))), ''), 'Unknown') AS email_domain,
	TRY_CAST(signup_date AS DATE)						AS signup_date
INTO Silver.customer
FROM Bronze.Customer;

-- primary key
ALTER TABLE Silver.customer ALTER COLUMN customer_id INT NOT NULL;
ALTER TABLE Silver.customer ADD CONSTRAINT PK_Silver_customer PRIMARY KEY (customer_id);
GO


-- data-quality flags 
ALTER TABLE Silver.customer ADD dq_signup_under_18   BIT NULL;
ALTER TABLE Silver.customer ADD dq_signup_before_dob BIT NULL;
GO

UPDATE Silver.customer
SET dq_signup_under_18   = CASE WHEN dob IS NOT NULL AND signup_date IS NOT NULL AND DATEADD(YEAR, 18, dob) > signup_date THEN 1 ELSE 0 END,
    dq_signup_before_dob = CASE WHEN dob IS NOT NULL AND signup_date IS NOT NULL AND signup_date < dob THEN 1 ELSE 0 END;
GO


-- ==================   Silver.merchant ==================

DROP TABLE IF EXISTS Silver.merchant;
GO

SELECT
	TRY_CAST(merchant_id AS INT)						AS merchant_id,
	ISNULL(NULLIF(
		CASE WHEN LTRIM(RTRIM(merchant_name)) LIKE 'fraud[_]%'
			 THEN SUBSTRING(LTRIM(RTRIM(merchant_name)), 7, 200)
			 ELSE LTRIM(RTRIM(merchant_name)) END, ''), 'Unknown')	AS merchant_name,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(dominant_category))), ''), 'unknown') AS merchant_category,
	ISNULL(NULLIF(LTRIM(RTRIM(merchant_city)), ''), 'Unknown')	AS merchant_city,
	ISNULL(NULLIF(UPPER(LTRIM(RTRIM(merchant_state))), ''), 'Unknown') AS merchant_state,
	TRY_CAST(merchant_lat  AS DECIMAL(9,6))				AS merchant_lat,
	TRY_CAST(merchant_long AS DECIMAL(9,6))				AS merchant_long,
	TRY_CAST(merchant_since AS DATE)					AS merchant_since,
	TRY_CAST(is_active AS BIT)							AS is_active
INTO Silver.merchant
FROM Bronze.Merchants;

-- primary key
ALTER TABLE Silver.merchant ALTER COLUMN merchant_id INT NOT NULL;
ALTER TABLE Silver.merchant ADD CONSTRAINT PK_Silver_merchant PRIMARY KEY (merchant_id);
GO


-- ==================   Silver.[transaction] ==================

DROP TABLE IF EXISTS Silver.[transaction];
GO

SELECT
	TRY_CAST(transaction_id AS INT)						AS transaction_id,
	TRY_CAST(trans_date_trans_time AS DATETIME2(0))		AS transaction_datetime,
	TRY_CAST(TRY_CAST(trans_date_trans_time AS DATETIME2(0)) AS DATE) AS transaction_date,
	TRY_CAST(customer_id AS INT)						AS customer_id,
	TRY_CAST(merchant_id AS INT)						AS merchant_id,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(category))), ''), 'unknown')	AS category,
	TRY_CAST(amt AS DECIMAL(12,2))						AS amount,
	ISNULL(TRY_CAST(tax_amt AS DECIMAL(12,2)), 0)		AS tax_amount,
	ISNULL(TRY_CAST(discount_amt AS DECIMAL(12,2)), 0)	AS discount_amount,
	ISNULL(NULLIF(UPPER(LTRIM(RTRIM(currency))), ''), 'UNK')		AS currency,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(payment_method))), ''), 'unknown')	AS payment_method,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(channel))), ''), 'unknown')			AS channel,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(entry_mode))), ''), 'unknown')		AS entry_mode,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(device_type))), ''), 'unknown')		AS device_type,
	ISNULL(NULLIF(LOWER(LTRIM(RTRIM(transaction_status))), ''), 'unknown') AS transaction_status,
	NULLIF(LTRIM(RTRIM(trans_num)), '')					AS trans_num,
	NULLIF(LTRIM(RTRIM(session_id)), '')				AS session_id,      
	TRY_CAST(unix_time AS BIGINT)						AS unix_time,
	ISNULL(TRY_CAST(is_fraud AS BIT), 0)				AS is_fraud
INTO Silver.[transaction]
FROM Bronze.[Transactions];

-- primary key
ALTER TABLE Silver.[transaction] ALTER COLUMN transaction_id INT NOT NULL;
ALTER TABLE Silver.[transaction] ADD CONSTRAINT PK_Silver_transaction PRIMARY KEY (transaction_id);
GO

-- data-quality flag: transaction dated before the customer's signup_date 
ALTER TABLE Silver.[transaction] ADD dq_before_signup BIT NULL;
GO

UPDATE t
SET dq_before_signup = CASE WHEN c.signup_date IS NOT NULL AND t.transaction_date < c.signup_date THEN 1 ELSE 0 END
FROM Silver.[transaction] AS t
LEFT JOIN Silver.customer AS c
	ON c.customer_id = t.customer_id;
GO


-- ==================   Silver checks ==================

-- row counts: Bronze vs Silver 
SELECT 'customer'    AS tbl, (SELECT COUNT(*) FROM Bronze.customer)       AS bronze_rows, (SELECT COUNT(*) FROM Silver.customer)       AS silver_rows
UNION ALL
SELECT 'merchant', (SELECT COUNT(*) FROM Bronze.Merchants),   (SELECT COUNT(*) FROM Silver.merchant)
UNION ALL
SELECT 'transaction',   (SELECT COUNT(*) FROM Bronze.[Transactions]),   (SELECT COUNT(*) FROM Silver.[transaction]);

-- amount reconciliation
SELECT
	(SELECT SUM(TRY_CAST(amt AS DECIMAL(14,2))) FROM Bronze.[Transactions]) AS bronze_amount,
	(SELECT SUM(amount) FROM Silver.[transaction]) AS silver_amount;

-- defaults applied 
SELECT 'loyalty_tier = Unassigned' AS applied, COUNT(*) AS CNT FROM Silver.customer WHERE loyalty_tier = 'Unassigned'
UNION ALL SELECT 'job = Unknown',           COUNT(*) FROM Silver.customer WHERE job = 'Unknown'
UNION ALL SELECT 'zip = Unknown',           COUNT(*) FROM Silver.customer WHERE zip = 'Unknown'
UNION ALL SELECT 'merchant_city = Unknown', COUNT(*) FROM Silver.merchant WHERE merchant_city = 'Unknown';

-- flags 
SELECT
	(SELECT SUM(CAST(dq_signup_under_18   AS INT)) FROM Silver.customer)       AS signup_under_18,
	(SELECT SUM(CAST(dq_signup_before_dob AS INT)) FROM Silver.customer)       AS signup_before_dob,
	(SELECT SUM(CAST(dq_before_signup     AS INT)) FROM Silver.[transaction])  AS txn_before_signup;

SELECT TOP 5 * FROM Silver.[transaction];

SELECT TOP 5 * FROM Silver.customer;

SELECT TOP 5 * FROM Silver.merchant;