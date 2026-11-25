USE [RetailBank];
GO
-- Customer

-- ========= 1- Nulls / blanks =========

SELECT
	SUM(CASE WHEN customer_id  IS NULL OR LTRIM(RTRIM(customer_id))  = '' THEN 1 ELSE 0 END) AS blank_customer_id,
	SUM(CASE WHEN cc_num       IS NULL OR LTRIM(RTRIM(cc_num))       = '' THEN 1 ELSE 0 END) AS blank_cc_num,
	SUM(CASE WHEN gender       IS NULL OR LTRIM(RTRIM(gender))       = '' THEN 1 ELSE 0 END) AS blank_gender,
	SUM(CASE WHEN zip          IS NULL OR LTRIM(RTRIM(zip))          = '' THEN 1 ELSE 0 END) AS blank_zip,         
	SUM(CASE WHEN job          IS NULL OR LTRIM(RTRIM(job))          = '' THEN 1 ELSE 0 END) AS blank_job,          
	SUM(CASE WHEN dob          IS NULL OR LTRIM(RTRIM(dob))          = '' THEN 1 ELSE 0 END) AS blank_dob,
	SUM(CASE WHEN loyalty_tier IS NULL OR LTRIM(RTRIM(loyalty_tier)) = '' THEN 1 ELSE 0 END) AS blank_loyalty_tier, 
	SUM(CASE WHEN signup_date  IS NULL OR LTRIM(RTRIM(signup_date))  = '' THEN 1 ELSE 0 END) AS blank_signup_date
FROM Bronze.customer;


-- ========= 2- Values that fail conversion  =========

SELECT * FROM Bronze.customer WHERE TRY_CAST(customer_id AS INT) IS NULL;

SELECT * FROM Bronze.customer WHERE TRY_CAST([lat]  AS DECIMAL(9,6)) IS NULL;

SELECT * FROM Bronze.customer WHERE TRY_CAST([long] AS DECIMAL(9,6)) IS NULL;

SELECT * FROM Bronze.customer WHERE TRY_CAST(city_pop AS INT) IS NULL;

SELECT * FROM Bronze.customer WHERE TRY_CAST(dob AS DATE) IS NULL;

SELECT * FROM Bronze.customer WHERE TRY_CAST(signup_date AS DATE) IS NULL;

SELECT COUNT(*) AS zip_stored_as_decimal FROM Bronze.customer WHERE zip LIKE '%.%';


-- ========= 3- Out of range =========

SELECT * FROM Bronze.customer WHERE TRY_CAST([lat]  AS DECIMAL(9,6)) NOT BETWEEN -90  AND 90;

SELECT * FROM Bronze.customer WHERE TRY_CAST([long] AS DECIMAL(9,6)) NOT BETWEEN -180 AND 180;

SELECT
	SUM(CASE WHEN DATEADD(YEAR, 18, TRY_CAST(dob AS DATE)) > TRY_CAST(signup_date AS DATE) THEN 1 ELSE 0 END) AS signup_under_18,
	SUM(CASE WHEN TRY_CAST(signup_date AS DATE) < TRY_CAST(dob AS DATE) THEN 1 ELSE 0 END)                    AS signup_before_dob
FROM Bronze.customer;


-- ========= 4- Inconsistent categorical values =========

SELECT gender,       COUNT(*) AS CNT FROM Bronze.customer GROUP BY gender;

SELECT loyalty_tier, COUNT(*) AS CNT FROM Bronze.customer GROUP BY loyalty_tier;

SELECT state,        COUNT(*) AS CNT FROM Bronze.customer GROUP BY state;

SELECT email_domain, COUNT(*) AS CNT FROM Bronze.customer GROUP BY email_domain;


-- ========= 5- Duplicate IDs  =========

SELECT customer_id, COUNT(*) AS CNT
FROM Bronze.customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT cc_num, COUNT(*) AS CNT
FROM Bronze.customer
GROUP BY cc_num
HAVING COUNT(*) > 1;


-- ========= 6- Total rows count =========

SELECT COUNT(*) AS total_rows FROM Bronze.customer;


-- merchant

-- ========= 1- Nulls / blanks =========

SELECT
	SUM(CASE WHEN merchant_id        IS NULL OR LTRIM(RTRIM(merchant_id))        = '' THEN 1 ELSE 0 END) AS blank_merchant_id,
	SUM(CASE WHEN merchant_name      IS NULL OR LTRIM(RTRIM(merchant_name))      = '' THEN 1 ELSE 0 END) AS blank_merchant_name,
	SUM(CASE WHEN dominant_category  IS NULL OR LTRIM(RTRIM(dominant_category))  = '' THEN 1 ELSE 0 END) AS blank_category,
	SUM(CASE WHEN merchant_city      IS NULL OR LTRIM(RTRIM(merchant_city))      = '' THEN 1 ELSE 0 END) AS blank_city,   -- expect 8
	SUM(CASE WHEN merchant_state     IS NULL OR LTRIM(RTRIM(merchant_state))     = '' THEN 1 ELSE 0 END) AS blank_state,
	SUM(CASE WHEN merchant_since     IS NULL OR LTRIM(RTRIM(merchant_since))     = '' THEN 1 ELSE 0 END) AS blank_since,
	SUM(CASE WHEN is_active          IS NULL OR LTRIM(RTRIM(is_active))          = '' THEN 1 ELSE 0 END) AS blank_is_active
FROM Bronze.Merchants;


-- ========= 2- Values that fail conversion  =========

SELECT * FROM Bronze.Merchants WHERE TRY_CAST(merchant_id    AS INT)           IS NULL;

SELECT * FROM Bronze.Merchants WHERE TRY_CAST(merchant_lat   AS DECIMAL(9,6))  IS NULL;

SELECT * FROM Bronze.Merchants WHERE TRY_CAST(merchant_long  AS DECIMAL(9,6))  IS NULL;

SELECT * FROM Bronze.Merchants WHERE TRY_CAST(merchant_since AS DATE)          IS NULL;

SELECT * FROM Bronze.Merchants WHERE TRY_CAST(is_active      AS BIT)           IS NULL;


-- ========= 3- Out of range =========

SELECT * FROM Bronze.Merchants WHERE TRY_CAST(merchant_lat  AS DECIMAL(9,6)) NOT BETWEEN -90  AND 90;

SELECT * FROM Bronze.Merchants WHERE TRY_CAST(merchant_long AS DECIMAL(9,6)) NOT BETWEEN -180 AND 180;


-- ========= 4- Inconsistent categorical values =========

SELECT dominant_category, COUNT(*) AS CNT FROM Bronze.Merchants GROUP BY dominant_category;

SELECT is_active, COUNT(*) AS CNT FROM Bronze.Merchants GROUP BY is_active;

SELECT COUNT(*) AS names_with_fraud_prefix FROM Bronze.Merchants WHERE merchant_name LIKE 'fraud[_]%';

SELECT COUNT(*) AS merchants, COUNT(DISTINCT merchant_name) AS distinct_names FROM Bronze.Merchants;


-- ========= 5- Duplicate IDs  =========

SELECT merchant_id, COUNT(*) AS CNT
FROM Bronze.Merchants
GROUP BY merchant_id
HAVING COUNT(*) > 1;


-- ========= 6- Total rows count =========

SELECT COUNT(*) AS total_rows FROM Bronze.Merchants;



-- transaction

-- ========= 1- Nulls / blanks =========

SELECT
	SUM(CASE WHEN transaction_id        IS NULL OR LTRIM(RTRIM(transaction_id))        = '' THEN 1 ELSE 0 END) AS blank_id,
	SUM(CASE WHEN trans_date_trans_time IS NULL OR LTRIM(RTRIM(trans_date_trans_time)) = '' THEN 1 ELSE 0 END) AS blank_datetime,
	SUM(CASE WHEN customer_id           IS NULL OR LTRIM(RTRIM(customer_id))           = '' THEN 1 ELSE 0 END) AS blank_customer_id,
	SUM(CASE WHEN merchant_id           IS NULL OR LTRIM(RTRIM(merchant_id))           = '' THEN 1 ELSE 0 END) AS blank_merchant_id,
	SUM(CASE WHEN amt                   IS NULL OR LTRIM(RTRIM(amt))                   = '' THEN 1 ELSE 0 END) AS blank_amt,
	SUM(CASE WHEN transaction_status    IS NULL OR LTRIM(RTRIM(transaction_status))    = '' THEN 1 ELSE 0 END) AS blank_status,
	SUM(CASE WHEN is_fraud              IS NULL OR LTRIM(RTRIM(is_fraud))              = '' THEN 1 ELSE 0 END) AS blank_is_fraud,
	SUM(CASE WHEN session_id            IS NULL OR LTRIM(RTRIM(session_id))            = '' THEN 1 ELSE 0 END) AS blank_session_id 
FROM Bronze.[Transactions];


-- ========= 2- Confirm blank session_id =========

SELECT
	channel,
	COUNT(*) AS CNT
FROM Bronze.[Transactions]
WHERE session_id IS NULL OR LTRIM(RTRIM(session_id)) = ''
GROUP BY channel;


-- ========= 3- Date conversion  =========

SELECT *
FROM Bronze.[Transactions]
WHERE TRY_CAST(trans_date_trans_time AS DATETIME2(0)) IS NULL;

SELECT
	MIN(TRY_CAST(trans_date_trans_time AS DATETIME2(0))) AS first_txn,
	MAX(TRY_CAST(trans_date_trans_time AS DATETIME2(0))) AS last_txn
FROM Bronze.[Transactions];


-- ========= 4- Numerical conversion  =========

SELECT * FROM Bronze.[Transactions] WHERE TRY_CAST(amt          AS DECIMAL(12,2)) IS NULL;

SELECT * FROM Bronze.[Transactions] WHERE TRY_CAST(tax_amt      AS DECIMAL(12,2)) IS NULL;

SELECT * FROM Bronze.[Transactions] WHERE TRY_CAST(discount_amt AS DECIMAL(12,2)) IS NULL;

SELECT * FROM Bronze.[Transactions] WHERE TRY_CAST(unix_time    AS BIGINT)        IS NULL;

SELECT * FROM Bronze.[Transactions] WHERE TRY_CAST(is_fraud     AS BIT)           IS NULL;

SELECT * FROM Bronze.[transactions] WHERE TRY_CAST(transaction_id AS INT) IS NULL;


-- ========= 5- Out of range / logic =========

SELECT
	SUM(CASE WHEN TRY_CAST(amt AS DECIMAL(12,2)) <= 0 THEN 1 ELSE 0 END)                                     AS non_positive_amt,
	SUM(CASE WHEN TRY_CAST(tax_amt AS DECIMAL(12,2)) > TRY_CAST(amt AS DECIMAL(12,2)) THEN 1 ELSE 0 END)      AS tax_gt_amt,
	SUM(CASE WHEN TRY_CAST(discount_amt AS DECIMAL(12,2)) > TRY_CAST(amt AS DECIMAL(12,2)) THEN 1 ELSE 0 END) AS discount_gt_amt
FROM Bronze.[Transactions];

-- channel / entry_mode / device_type must agree 
SELECT COUNT(*) AS inconsistent_channel
FROM Bronze.[Transactions]
WHERE (channel = 'online'   AND (entry_mode <> 'online' OR device_type = 'pos_terminal'))
   OR (channel = 'in_store' AND (entry_mode = 'online'  OR device_type <> 'pos_terminal'));

-- unix_time must equal the datetime 
SELECT COUNT(*) AS unix_mismatch
FROM Bronze.[Transactions]
WHERE DATEDIFF_BIG(SECOND, '1970-01-01', TRY_CAST(trans_date_trans_time AS DATETIME2(0))) <> TRY_CAST(unix_time AS BIGINT);


-- ========= 6- Orphan transactions (all expect 0) =========

SELECT COUNT(*) AS orphan_customers
FROM Bronze.[Transactions] AS t
LEFT JOIN Bronze.customer AS c
	ON TRY_CAST(c.customer_id AS INT) = TRY_CAST(t.customer_id AS INT)
WHERE c.customer_id IS NULL;


SELECT COUNT(*) AS orphan_merchants
FROM Bronze.[Transactions] AS t
LEFT JOIN Bronze.Merchants AS m
	ON TRY_CAST(m.merchant_id AS INT) = TRY_CAST(t.merchant_id AS INT)
WHERE m.merchant_id IS NULL;


-- ========= 7- Distinct categorical values =========

SELECT category,           COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY category;

SELECT currency,           COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY currency;

SELECT payment_method,     COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY payment_method;

SELECT channel,            COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY channel;

SELECT entry_mode,         COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY entry_mode;

SELECT device_type,        COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY device_type;

SELECT transaction_status, COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY transaction_status;

SELECT is_fraud,           COUNT(*) AS CNT FROM Bronze.[Transactions] GROUP BY is_fraud;

-- fraud flag vs status
SELECT transaction_status, is_fraud, COUNT(*) AS CNT
FROM Bronze.[Transactions]
GROUP BY transaction_status, is_fraud
ORDER BY transaction_status, is_fraud;


-- ========= 8- Duplicate transaction IDs  =========

SELECT transaction_id, COUNT(*) AS CNT
FROM Bronze.[Transactions]
GROUP BY transaction_id
HAVING COUNT(*) > 1;

SELECT trans_num, COUNT(*) AS CNT
FROM Bronze.[Transactions]
GROUP BY trans_num
HAVING COUNT(*) > 1;


-- ========= 9- Business-rule checks across tables =========

-- transactions BEFORE the customer signed up
SELECT COUNT(*) AS txn_before_signup
FROM Bronze.[Transactions] AS t
JOIN Bronze.customer AS c
	ON TRY_CAST(c.customer_id AS INT) = TRY_CAST(t.customer_id AS INT)
WHERE TRY_CAST(t.trans_date_trans_time AS DATETIME2(0)) < TRY_CAST(c.signup_date AS DATE);

-- transactions at merchants that are now inactive 
SELECT COUNT(*) AS txn_at_inactive_merchant
FROM Bronze.[Transactions] AS t
JOIN Bronze.Merchants AS m
	ON TRY_CAST(m.merchant_id AS INT) = TRY_CAST(t.merchant_id AS INT)
WHERE m.is_active = '0';

-- transaction category <> merchant dominant category 
SELECT COUNT(*) AS category_differs
FROM Bronze.[Transactions] AS t
JOIN Bronze.Merchants AS m
	ON TRY_CAST(m.merchant_id AS INT) = TRY_CAST(t.merchant_id AS INT)
WHERE t.category <> m.dominant_category;


-- ========= 10- Total rows count =========

SELECT COUNT(*) AS Total_Rows FROM Bronze.[Transactions];