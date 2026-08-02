-- =====================================================
-- 1. DATABASE AND TABLE SETUP
-- =====================================================

-- 1.1 CREATE DATABASE
CREATE DATABASE IF NOT EXISTS marketing_funnel;
USE marketing_funnel;


-- 1.2 CREATE TABLE STRUCTURE
-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY,
    date DATE,
    device VARCHAR(20),
    sex VARCHAR(10)
);

-- HOME TABLE 
CREATE TABLE IF NOT EXISTS home (
    user_id INT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- SEARCH TABLE
CREATE TABLE IF NOT EXISTS search (
    user_id INT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- PAYMENT TABLE
CREATE TABLE IF NOT EXISTS payment (
    user_id INT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- PAYMENT CONFIRMATION TABLE
CREATE TABLE IF NOT EXISTS payment_confirmation (
    user_id INT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 1.3 INSERT DATA INTO TABLES
-- Run the data-loading section only once unless the existing tables are cleared.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/user_table.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(user_id, date, device, sex);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/home_page_table.csv'
INTO TABLE home
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(user_id, @page);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/search_page_table.csv'
INTO TABLE search
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(user_id, @page);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payment_page_table.csv'
INTO TABLE payment
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(user_id, @page);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payment_confirmation_table.csv'
INTO TABLE payment_confirmation
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(user_id, @page);

-- =====================================================
-- 2. DATA QUALITY VALIDATION
-- =====================================================

-- 2.1 TABLE ROW COUNT VALIDATION
SELECT 'users' AS table_name, COUNT(*) AS row_count
FROM users
UNION ALL
SELECT 'home', COUNT(*)
FROM home
UNION ALL
SELECT 'search', COUNT(*)
FROM search
UNION ALL
SELECT 'payment', COUNT(*)
FROM payment
UNION ALL
SELECT 'payment_confirmation', COUNT(*)
FROM payment_confirmation;
# The row counts matched the source datasets and the previously validated Python analysis. 


-- 2.2 MISSING VALUE VALIDATION
SELECT
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS null_dates,
    SUM(CASE WHEN sex IS NULL THEN 1 ELSE 0 END) AS null_sex,
    SUM(CASE WHEN device IS NULL THEN 1 ELSE 0 END) AS null_device
FROM users;
# No missing values were identified in the required date, device or gender fields.


-- 2.3 CATEGORICAL VALUE VALIDATION
-- Sex
SELECT
    sex,
    COUNT(*) AS user_count
FROM users
GROUP BY sex
ORDER BY user_count DESC;

-- Device
SELECT 
	device,
    COUNT(*) AS user_count
FROM users
GROUP BY device
ORDER BY user_count DESC;

SELECT *
FROM users
WHERE sex NOT IN ('Male', 'Female')
   OR device NOT IN ('Desktop', 'Mobile')
   OR sex IS NULL
   OR device IS NULL;
# The demographic fields contained only the expected categories. 
# Device was limited to Desktop and Mobile, while gender was limited to Male and Female, with no invalid or inconsistent category labels detected.


-- 2.4 FUNNEL SEQUENCE VALIDATION
SELECT
    'Search without Home' AS validation_check,
    COUNT(*) AS inconsistent_users
FROM search s
LEFT JOIN home h
    ON s.user_id = h.user_id
WHERE h.user_id IS NULL
UNION ALL
SELECT
    'Payment without Search',
    COUNT(*)
FROM payment p
LEFT JOIN search s
    ON p.user_id = s.user_id
WHERE s.user_id IS NULL
UNION ALL
SELECT
    'Confirmation without Payment',
    COUNT(*)
FROM payment_confirmation pc
LEFT JOIN payment p
    ON pc.user_id = p.user_id
WHERE p.user_id IS NULL;
# No funnel-order inconsistencies were identified. 
# Every user recorded at a later stage was also present in the immediately preceding stage, confirming that the stage tables represent a valid sequential funnel.


-- 2.5 DATE VALIDATION
SELECT
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date,
    COUNT(DISTINCT date) AS distinct_dates,
    COUNT(DISTINCT DATE_FORMAT(date, '%Y-%m')) AS month_groups,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS null_dates
FROM users;
# The date field contained no missing values and covered the expected analysis period. 
# The values were stored in a valid SQL date format, allowing users to be grouped consistently into monthly user groups.


-- =====================================================
-- 3. USER-LEVEL FUNNEL MODEL
-- =====================================================

-- 3.1 CREATE ANALYSIS-READY USER FUNNEL VIEW
CREATE OR REPLACE VIEW user_funnel AS
SELECT
    u.user_id,
    u.date,
    DATE_FORMAT(u.date, '%Y-%m') AS user_month,
    u.sex,
    u.device,
    CASE
        WHEN h.user_id IS NOT NULL THEN 1
        ELSE 0
    END AS reached_home,
    CASE
        WHEN s.user_id IS NOT NULL THEN 1
        ELSE 0
    END AS reached_search,
    CASE
        WHEN p.user_id IS NOT NULL THEN 1
        ELSE 0
    END AS reached_payment,
    CASE
        WHEN pc.user_id IS NOT NULL THEN 1
        ELSE 0
    END AS converted,
    CASE
        WHEN s.user_id IS NULL THEN 'Home to Search'
        WHEN p.user_id IS NULL THEN 'Search to Payment'
        WHEN pc.user_id IS NULL THEN 'Payment to Confirmation'
        ELSE 'Converted'
    END AS drop_off_stage
FROM users u
LEFT JOIN home h
    ON u.user_id = h.user_id
LEFT JOIN search s
    ON u.user_id = s.user_id
LEFT JOIN payment p
    ON u.user_id = p.user_id
LEFT JOIN payment_confirmation pc
    ON u.user_id = pc.user_id;
# The five source tables were consolidated into a single user-level view containing 
# demographic attributes, monthly user groups, funnel-stage indicators and user drop-off classifications.

-- 3.2 Preview the view
SELECT *
FROM user_funnel
LIMIT 10;


-- 3.3 Validate row level uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT user_id) AS unique_users
FROM user_funnel;
# The final view contains one record for each of the 90,400 users, confirming that the joins did not create duplicate rows.


-- 3.4 Validate Drop-off Classification
SELECT
    drop_off_stage,
    COUNT(*) AS user_count
FROM user_funnel
GROUP BY drop_off_stage
ORDER BY user_count DESC;
# Each user was assigned to one mutually exclusive funnel outcome.


-- =====================================================
-- 4. ANALYTICAL VIEWS
-- =====================================================

-- 4.1 FUNNEL SUMMARY VIEW
CREATE OR REPLACE VIEW funnel_summary AS
SELECT
    1 AS stage_order,
    'Home' AS funnel_stage,
    SUM(reached_home) AS users_reached,
    SUM(reached_search) AS users_progressed,
    SUM(reached_home) - SUM(reached_search) AS drop_off_users,
    ROUND(
        100.0 * SUM(reached_search) / NULLIF(SUM(reached_home), 0),
        2
    ) AS stage_conversion_rate,
    ROUND(
        100.0 * (SUM(reached_home) - SUM(reached_search))
        / NULLIF(SUM(reached_home), 0),
        2
    ) AS abandonment_rate
FROM user_funnel
UNION ALL
SELECT
    2,
    'Search',
    SUM(reached_search),
    SUM(reached_payment),
    SUM(reached_search) - SUM(reached_payment),
    ROUND(
        100.0 * SUM(reached_payment) / NULLIF(SUM(reached_search), 0),
        2
    ),
    ROUND(
        100.0 * (SUM(reached_search) - SUM(reached_payment))
        / NULLIF(SUM(reached_search), 0),
        2
    )
FROM user_funnel
UNION ALL
SELECT
    3,
    'Payment',
    SUM(reached_payment),
    SUM(converted),
    SUM(reached_payment) - SUM(converted),
    ROUND(
        100.0 * SUM(converted) / NULLIF(SUM(reached_payment), 0),
        2
    ),
    ROUND(
        100.0 * (SUM(reached_payment) - SUM(converted))
        / NULLIF(SUM(reached_payment), 0),
        2
    )
FROM user_funnel
UNION ALL
SELECT
    4,
    'Confirmation',
    SUM(converted),
    NULL,
    0,
    NULL,
    NULL
FROM user_funnel;

SELECT *
FROM funnel_summary
ORDER BY stage_order;
# The Search → Payment transition accounts for the largest absolute customer loss, while Payment → Confirmation 
# records the highest proportional abandonment. These two stages should therefore be treated as distinct optimisation priorities.


-- 4.2 DEVICE FUNNEL SUMMARY VIEW
CREATE OR REPLACE VIEW device_funnel_summary AS
SELECT
    device,
    COUNT(*) AS total_users,
    SUM(reached_search) AS search_users,
    SUM(reached_payment) AS payment_users,
    SUM(converted) AS confirmed_users,
    ROUND(
        100.0 * SUM(reached_search) / NULLIF(COUNT(*), 0),
        2
    ) AS home_to_search_rate,
    ROUND(
        100.0 * SUM(reached_payment)
        / NULLIF(SUM(reached_search), 0),
        2
    ) AS search_to_payment_rate,
    ROUND(
        100.0 * SUM(converted)
        / NULLIF(SUM(reached_payment), 0),
        2
    ) AS payment_to_confirmation_rate,
    ROUND(
        100.0 * SUM(converted) / NULLIF(COUNT(*), 0),
        2
    ) AS overall_conversion_rate
FROM user_funnel
GROUP BY device;

SELECT * FROM device_funnel_summary
ORDER BY overall_conversion_rate DESC;
# Mobile users achieved a higher overall conversion rate than Desktop users.
# The stage-level rates indicate that the Desktop funnel should receive greater attention during further investigation and optimisation.


-- 4.3 MONTHLY USER-GROUP SUMMARY VIEW
CREATE OR REPLACE VIEW monthly_funnel_summary AS
SELECT
    user_month,
    COUNT(*) AS total_users,
    SUM(reached_search) AS search_users,
    SUM(reached_payment) AS payment_users,
    SUM(converted) AS confirmed_users,
    ROUND(
        100.0 * SUM(reached_search) / NULLIF(COUNT(*), 0),
        2
    ) AS home_to_search_rate,
    ROUND(
        100.0 * SUM(reached_payment)
        / NULLIF(SUM(reached_search), 0),
        2
    ) AS search_to_payment_rate,
    ROUND(
        100.0 * SUM(converted)
        / NULLIF(SUM(reached_payment), 0),
        2
    ) AS payment_to_confirmation_rate,
    ROUND(
        100.0 * SUM(converted) / NULLIF(COUNT(*), 0),
        2
    ) AS overall_conversion_rate
FROM user_funnel
GROUP BY user_month;

SELECT *
FROM monthly_funnel_summary
ORDER BY user_month;
# Users associated with the March and April groups exhibited weaker funnel performance than those associated with January and February. 
# The dataset does not identify the cause, so these differences should be treated as areas for further investigation rather than evidence of a specific time-based decline.
-- *Note:
-- Funnel-stage tables do not contain event timestamps.
-- Monthly comparisons are therefore based on the date recorded
-- in the users table, not the exact timing of stage events.


-- =====================================================
-- 5. FINAL OUTPUT VALIDATION
-- =====================================================

-- 5.1 FUNNEL TOTAL RECONCILIATION
SELECT
    SUM(reached_home) AS model_home_users,
    (SELECT COUNT(*) FROM home) AS source_home_users,
    SUM(reached_search) AS model_search_users,
    (SELECT COUNT(*) FROM search) AS source_search_users,
    SUM(reached_payment) AS model_payment_users,
    (SELECT COUNT(*) FROM payment) AS source_payment_users,
    SUM(converted) AS model_confirmation_users,
    (SELECT COUNT(*) FROM payment_confirmation) AS source_confirmation_users
FROM user_funnel;
# Funnel-stage totals from the user-level model matched the original source-table counts, confirming that the transformation preserved all stage records correctly.


-- 5.2 SEGMENT TOTAL VALIDATION
SELECT
    (SELECT SUM(total_users)
     FROM device_funnel_summary) AS device_total,

    (SELECT SUM(total_users)
     FROM monthly_funnel_summary) AS monthly_total,

    (SELECT COUNT(*)
     FROM user_funnel) AS model_total;
# Device and monthly user-group views each reconciled to the complete user population, confirming that no users were lost or duplicated during aggregation.

-- 5.3 CONVERSION TOTAL VALIDATION
SELECT
    (SELECT SUM(converted)
     FROM user_funnel) AS model_confirmed,

    (SELECT SUM(confirmed_users)
     FROM device_funnel_summary) AS device_confirmed,

    (SELECT SUM(confirmed_users)
     FROM monthly_funnel_summary) AS monthly_confirmed;
# Confirmed-user totals remained consistent across the user-level model and all analytical views, validating the conversion logic used throughout the SQL pipeline.