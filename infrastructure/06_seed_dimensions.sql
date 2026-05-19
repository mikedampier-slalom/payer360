-- =============================================================================
-- Payer360 Demo: Seed Dimension Tables with Synthetic Data
-- =============================================================================
-- Run as: SYSADMIN on P360_LOAD_WH
-- Prerequisite: 03_dimensions.sql executed (tables exist, empty)
-- Scale: Demo — 50K members, 500 providers, 20 plans, 8 regions
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE P360_LOAD_WH;

-- =============================================================================
-- 1. DIM_DATE — 3-year date spine (2023-01-01 to 2025-12-31)
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.COMMON.DIM_DATE;

INSERT INTO PAYER360_CUR.COMMON.DIM_DATE
WITH date_spine AS (
    SELECT DATEADD(DAY, SEQ4(), '2023-01-01'::DATE) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1096))  -- 3 years
)
SELECT
    YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d) AS DATE_KEY,
    d AS FULL_DATE,
    YEAR(d) AS YEAR,
    QUARTER(d) AS QUARTER,
    MONTH(d) AS MONTH,
    MONTHNAME(d) AS MONTH_NAME,
    DAY(d) AS DAY_OF_MONTH,
    DAYOFWEEK(d) AS DAY_OF_WEEK,
    DAYNAME(d) AS DAY_NAME,
    WEEKOFYEAR(d) AS WEEK_OF_YEAR,
    -- Fiscal year starts January 1 (calendar year for payers)
    YEAR(d) AS FISCAL_YEAR,
    QUARTER(d) AS FISCAL_QUARTER,
    DAYOFWEEK(d) IN (0, 6) AS IS_WEEKEND,
    -- Major US holidays (simplified)
    CASE
        WHEN MONTH(d) = 1  AND DAY(d) = 1  THEN TRUE
        WHEN MONTH(d) = 7  AND DAY(d) = 4  THEN TRUE
        WHEN MONTH(d) = 12 AND DAY(d) = 25 THEN TRUE
        WHEN MONTH(d) = 11 AND DAYOFWEEK(d) = 4 AND DAY(d) BETWEEN 22 AND 28 THEN TRUE
        WHEN MONTH(d) = 9  AND DAYOFWEEK(d) = 1 AND DAY(d) <= 7 THEN TRUE
        WHEN MONTH(d) = 5  AND DAYOFWEEK(d) = 1 AND DAY(d) >= 25 THEN TRUE
        ELSE FALSE
    END AS IS_HOLIDAY,
    CASE
        WHEN MONTH(d) = 1  AND DAY(d) = 1  THEN 'New Year''s Day'
        WHEN MONTH(d) = 7  AND DAY(d) = 4  THEN 'Independence Day'
        WHEN MONTH(d) = 12 AND DAY(d) = 25 THEN 'Christmas Day'
        WHEN MONTH(d) = 11 AND DAYOFWEEK(d) = 4 AND DAY(d) BETWEEN 22 AND 28 THEN 'Thanksgiving'
        WHEN MONTH(d) = 9  AND DAYOFWEEK(d) = 1 AND DAY(d) <= 7 THEN 'Labor Day'
        WHEN MONTH(d) = 5  AND DAYOFWEEK(d) = 1 AND DAY(d) >= 25 THEN 'Memorial Day'
        ELSE NULL
    END AS HOLIDAY_NAME
FROM date_spine
WHERE d <= '2025-12-31';

-- =============================================================================
-- 2. DIM_LINE_OF_BUSINESS — 5 lines of business
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.FINANCIAL.DIM_LINE_OF_BUSINESS;

INSERT INTO PAYER360_CUR.FINANCIAL.DIM_LINE_OF_BUSINESS
    (LOB_ID, LOB_NAME, DESCRIPTION, MLR_THRESHOLD, REGULATORY_BODY, IS_ACTIVE)
VALUES
    ('IND',  'Individual',              'ACA individual marketplace plans',                      0.80, 'CMS',       TRUE),
    ('SG',   'Small Group',             'Employer groups with 2-50 employees',                   0.80, 'CMS',       TRUE),
    ('LG',   'Large Group',             'Employer groups with 51+ employees',                    0.85, 'CMS',       TRUE),
    ('MA',   'Medicare Advantage',      'Medicare Part C managed care plans',                    0.85, 'CMS',       TRUE),
    ('MCO',  'Medicaid Managed Care',   'State Medicaid managed care contracts',                 0.85, 'State DOI', TRUE);

-- =============================================================================
-- 3. DIM_REGION — 8 geographic regions
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.NETWORK.DIM_REGION;

INSERT INTO PAYER360_CUR.NETWORK.DIM_REGION
    (REGION_ID, REGION_NAME, STATE, MARKET_TYPE, POPULATION, MEMBER_DENSITY)
VALUES
    ('REG-NE',  'Northeast',         'NY', 'Urban',    5200000, 42.5),
    ('REG-SE',  'Southeast',         'GA', 'Suburban', 3800000, 28.3),
    ('REG-MW',  'Midwest',           'IL', 'Urban',    4500000, 35.7),
    ('REG-SW',  'Southwest',         'TX', 'Suburban', 4100000, 22.1),
    ('REG-WC',  'West Coast',        'CA', 'Urban',    6100000, 48.9),
    ('REG-MT',  'Mountain',          'CO', 'Rural',    2200000, 12.4),
    ('REG-MA',  'Mid-Atlantic',      'PA', 'Suburban', 3600000, 31.8),
    ('REG-PNW', 'Pacific Northwest', 'WA', 'Suburban', 2900000, 25.6);

-- =============================================================================
-- 4. DIM_PLAN — 20 health plans
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.MEMBERSHIP.DIM_PLAN;

INSERT INTO PAYER360_CUR.MEMBERSHIP.DIM_PLAN
    (PLAN_ID, PLAN_NAME, PLAN_TYPE, LINE_OF_BUSINESS, METAL_TIER, MONTHLY_PREMIUM, DEDUCTIBLE, MAX_OOP, COPAY_PCP, COPAY_SPECIALIST, IS_ACTIVE, EFFECTIVE_DATE)
VALUES
    -- Individual Plans
    ('PLN-IND-BRZ', 'Bronze Essential',       'HMO',  'Individual', 'Bronze',   320.00, 7000.00, 8700.00,  40.00, 80.00, TRUE, '2023-01-01'),
    ('PLN-IND-SLV', 'Silver Standard',        'PPO',  'Individual', 'Silver',   480.00, 4500.00, 7500.00,  30.00, 60.00, TRUE, '2023-01-01'),
    ('PLN-IND-GLD', 'Gold Premium',           'PPO',  'Individual', 'Gold',     650.00, 1500.00, 5000.00,  20.00, 40.00, TRUE, '2023-01-01'),
    ('PLN-IND-PLT', 'Platinum Elite',         'EPO',  'Individual', 'Platinum', 850.00,  500.00, 3000.00,  10.00, 25.00, TRUE, '2023-01-01'),
    -- Small Group Plans
    ('PLN-SG-BAS',  'SmallBiz Basic',         'HMO',  'Small Group','Bronze',   380.00, 6000.00, 8000.00,  35.00, 70.00, TRUE, '2023-01-01'),
    ('PLN-SG-STD',  'SmallBiz Standard',      'PPO',  'Small Group','Silver',   520.00, 3500.00, 6500.00,  25.00, 50.00, TRUE, '2023-01-01'),
    ('PLN-SG-PRM',  'SmallBiz Premium',       'PPO',  'Small Group','Gold',     710.00, 1500.00, 4500.00,  20.00, 40.00, TRUE, '2023-01-01'),
    ('PLN-SG-HDH',  'SmallBiz HDHP',         'HDHP', 'Small Group','Bronze',   290.00, 7000.00, 14000.00, 0.00,  0.00,  TRUE, '2023-01-01'),
    -- Large Group Plans
    ('PLN-LG-BAS',  'Enterprise Basic',       'HMO',  'Large Group', NULL,      420.00, 3000.00, 6000.00,  25.00, 50.00, TRUE, '2023-01-01'),
    ('PLN-LG-STD',  'Enterprise Standard',    'PPO',  'Large Group', NULL,      580.00, 2000.00, 5000.00,  20.00, 40.00, TRUE, '2023-01-01'),
    ('PLN-LG-PRM',  'Enterprise Premium',     'PPO',  'Large Group', NULL,      780.00, 1000.00, 3500.00,  15.00, 30.00, TRUE, '2023-01-01'),
    ('PLN-LG-POS',  'Enterprise POS',         'POS',  'Large Group', NULL,      550.00, 2500.00, 5500.00,  20.00, 45.00, TRUE, '2023-01-01'),
    -- Medicare Advantage Plans
    ('PLN-MA-HMO',  'Medicare Gold HMO',      'HMO',  'Medicare Advantage', NULL, 0.00, 0.00,   6700.00,  0.00,  20.00, TRUE, '2023-01-01'),
    ('PLN-MA-PPO',  'Medicare Choice PPO',    'PPO',  'Medicare Advantage', NULL, 45.00, 0.00,   7550.00,  10.00, 35.00, TRUE, '2023-01-01'),
    ('PLN-MA-HDH',  'Medicare HDHP',          'HDHP', 'Medicare Advantage', NULL, 0.00,  500.00, 5000.00,  0.00,  0.00,  TRUE, '2023-01-01'),
    ('PLN-MA-SNP',  'Medicare Special Needs', 'HMO',  'Medicare Advantage', NULL, 0.00,  0.00,   3000.00,  0.00,  10.00, TRUE, '2023-01-01'),
    -- Medicaid Managed Care Plans
    ('PLN-MCO-STD', 'Medicaid Complete',      'HMO',  'Medicaid Managed Care', NULL, 0.00, 0.00, 0.00,    0.00,  0.00,  TRUE, '2023-01-01'),
    ('PLN-MCO-FAM', 'Medicaid Family',        'HMO',  'Medicaid Managed Care', NULL, 0.00, 0.00, 0.00,    0.00,  0.00,  TRUE, '2023-01-01'),
    ('PLN-MCO-ABD', 'Medicaid ABD',           'HMO',  'Medicaid Managed Care', NULL, 0.00, 0.00, 0.00,    0.00,  0.00,  TRUE, '2023-01-01'),
    ('PLN-MCO-CHP', 'Medicaid CHIP',          'HMO',  'Medicaid Managed Care', NULL, 0.00, 0.00, 0.00,    0.00,  0.00,  TRUE, '2023-01-01');

-- =============================================================================
-- 5. DIM_MEMBER — 50K members via GENERATOR
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.MEMBERSHIP.DIM_MEMBER;

INSERT INTO PAYER360_CUR.MEMBERSHIP.DIM_MEMBER
    (MEMBER_ID, FIRST_NAME, LAST_NAME, DOB, GENDER, RACE, LANGUAGE, PHONE, EMAIL,
     ADDRESS, CITY, STATE, ZIP, COUNTY, PLAN_ID, LINE_OF_BUSINESS,
     ENROLLMENT_DATE, RISK_SCORE, CHRONIC_CONDITION_COUNT, IS_ACTIVE)
WITH
first_names AS (
    SELECT COLUMN1 AS name, ROW_NUMBER() OVER (ORDER BY 1) AS rn FROM (VALUES
        ('James'),('Mary'),('John'),('Patricia'),('Robert'),('Jennifer'),('Michael'),('Linda'),
        ('David'),('Elizabeth'),('William'),('Barbara'),('Richard'),('Susan'),('Joseph'),('Jessica'),
        ('Thomas'),('Sarah'),('Charles'),('Karen'),('Christopher'),('Lisa'),('Daniel'),('Nancy'),
        ('Matthew'),('Betty'),('Anthony'),('Margaret'),('Mark'),('Sandra'),('Donald'),('Ashley'),
        ('Steven'),('Dorothy'),('Andrew'),('Kimberly'),('Paul'),('Emily'),('Joshua'),('Donna')
    )
),
last_names AS (
    SELECT COLUMN1 AS name, ROW_NUMBER() OVER (ORDER BY 1) AS rn FROM (VALUES
        ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),('Davis'),
        ('Rodriguez'),('Martinez'),('Hernandez'),('Lopez'),('Gonzalez'),('Wilson'),('Anderson'),
        ('Thomas'),('Taylor'),('Moore'),('Jackson'),('Martin'),('Lee'),('Perez'),('Thompson'),
        ('White'),('Harris'),('Sanchez'),('Clark'),('Ramirez'),('Lewis'),('Robinson'),
        ('Walker'),('Young'),('Allen'),('King'),('Wright'),('Scott'),('Torres'),('Nguyen'),
        ('Hill'),('Flores')
    )
),
plan_list AS (
    SELECT PLAN_ID, LINE_OF_BUSINESS, ROW_NUMBER() OVER (ORDER BY PLAN_ID) AS rn
    FROM PAYER360_CUR.MEMBERSHIP.DIM_PLAN
    WHERE IS_ACTIVE = TRUE
),
states_data AS (
    SELECT COLUMN1 AS state_abbr, COLUMN2 AS city_name, COLUMN3 AS zip_code, COLUMN4 AS county_name,
           ROW_NUMBER() OVER (ORDER BY 1) AS rn FROM (VALUES
        ('NY','New York','10001','New York'),('CA','Los Angeles','90001','Los Angeles'),
        ('TX','Houston','77001','Harris'),('IL','Chicago','60601','Cook'),
        ('PA','Philadelphia','19101','Philadelphia'),('GA','Atlanta','30301','Fulton'),
        ('WA','Seattle','98101','King'),('CO','Denver','80201','Denver'),
        ('FL','Miami','33101','Miami-Dade'),('MA','Boston','02101','Suffolk'),
        ('OH','Columbus','43201','Franklin'),('NC','Charlotte','28201','Mecklenburg'),
        ('AZ','Phoenix','85001','Maricopa'),('MI','Detroit','48201','Wayne'),
        ('MN','Minneapolis','55401','Hennepin')
    )
),
base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        UNIFORM(1, 40, RANDOM()) AS fn_idx,
        UNIFORM(1, 40, RANDOM()) AS ln_idx,
        UNIFORM(1, 20, RANDOM()) AS plan_idx,
        UNIFORM(1, 15, RANDOM()) AS state_idx,
        DATEADD(DAY, -UNIFORM(6570, 31025, RANDOM()), CURRENT_DATE()) AS dob_val,
        DATEADD(DAY, -UNIFORM(0, 1825, RANDOM()), '2025-06-01'::DATE) AS enroll_val,
        ROUND(UNIFORM(50, 400, RANDOM()) / 100.0, 2) AS risk_val,
        UNIFORM(0, 5, RANDOM()) AS chronic_val,
        CASE UNIFORM(1, 10, RANDOM()) WHEN 10 THEN FALSE ELSE TRUE END AS active_val,
        CASE UNIFORM(1, 2, RANDOM()) WHEN 1 THEN 'Male' ELSE 'Female' END AS gender_val
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
)
SELECT
    'MBR-' || LPAD(b.row_id::STRING, 6, '0') AS MEMBER_ID,
    fn.name AS FIRST_NAME,
    ln.name AS LAST_NAME,
    b.dob_val AS DOB,
    b.gender_val AS GENDER,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'White' WHEN 2 THEN 'Black' WHEN 3 THEN 'Hispanic'
        WHEN 4 THEN 'Asian' ELSE 'Other'
    END AS RACE,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'English' WHEN 2 THEN 'Spanish' WHEN 3 THEN 'Mandarin' ELSE 'English'
    END AS LANGUAGE,
    '555-' || LPAD(UNIFORM(1000, 9999, RANDOM())::STRING, 4, '0') || '-' || LPAD(UNIFORM(1000, 9999, RANDOM())::STRING, 4, '0') AS PHONE,
    LOWER(fn.name) || '.' || LOWER(ln.name) || b.row_id::STRING || '@email.com' AS EMAIL,
    UNIFORM(100, 9999, RANDOM())::STRING || ' Main St' AS ADDRESS,
    sd.city_name AS CITY,
    sd.state_abbr AS STATE,
    sd.zip_code AS ZIP,
    sd.county_name AS COUNTY,
    pl.PLAN_ID,
    pl.LINE_OF_BUSINESS,
    b.enroll_val AS ENROLLMENT_DATE,
    b.risk_val AS RISK_SCORE,
    b.chronic_val AS CHRONIC_CONDITION_COUNT,
    b.active_val AS IS_ACTIVE
FROM base b
JOIN first_names fn ON fn.rn = b.fn_idx
JOIN last_names ln ON ln.rn = b.ln_idx
JOIN plan_list pl ON pl.rn = b.plan_idx
JOIN states_data sd ON sd.rn = b.state_idx;

-- =============================================================================
-- 6. DIM_PROVIDER — 500 providers via GENERATOR
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.NETWORK.DIM_PROVIDER;

INSERT INTO PAYER360_CUR.NETWORK.DIM_PROVIDER
    (NPI, FIRST_NAME, LAST_NAME, CREDENTIAL, SPECIALTY, SUBSPECIALTY, PRACTICE_NAME,
     PRACTICE_TYPE, ADDRESS, CITY, STATE, ZIP, REGION_ID, CONTRACT_STATUS, CONTRACT_START, IS_ACTIVE)
WITH
first_names AS (
    SELECT COLUMN1 AS name, ROW_NUMBER() OVER (ORDER BY 1) AS rn FROM (VALUES
        ('James'),('Sarah'),('Michael'),('Emily'),('David'),('Jessica'),('Robert'),('Amanda'),
        ('William'),('Rachel'),('Daniel'),('Nicole'),('Christopher'),('Stephanie'),('Andrew'),
        ('Michelle'),('Kevin'),('Laura'),('Brian'),('Jennifer')
    )
),
last_names AS (
    SELECT COLUMN1 AS name, ROW_NUMBER() OVER (ORDER BY 1) AS rn FROM (VALUES
        ('Patel'),('Kim'),('Chen'),('Singh'),('Shah'),('Nguyen'),('Lee'),('Park'),
        ('Wang'),('Kumar'),('Johnson'),('Williams'),('Brown'),('Davis'),('Garcia'),
        ('Martinez'),('Robinson'),('Clark'),('Lewis'),('Walker')
    )
),
specialties AS (
    SELECT COLUMN1 AS spec, ROW_NUMBER() OVER (ORDER BY 1) AS rn FROM (VALUES
        ('Family Medicine'),('Internal Medicine'),('Cardiology'),('Orthopedics'),
        ('Dermatology'),('Gastroenterology'),('Neurology'),('Oncology'),
        ('Pediatrics'),('Psychiatry'),('Pulmonology'),('Endocrinology'),
        ('Rheumatology'),('Urology'),('General Surgery'),('OB/GYN'),
        ('Ophthalmology'),('ENT'),('Radiology'),('Emergency Medicine')
    )
),
regions AS (
    SELECT REGION_ID, ROW_NUMBER() OVER (ORDER BY REGION_ID) AS rn
    FROM PAYER360_CUR.NETWORK.DIM_REGION
),
base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        UNIFORM(1, 20, RANDOM()) AS fn_idx,
        UNIFORM(1, 20, RANDOM()) AS ln_idx,
        UNIFORM(1, 20, RANDOM()) AS spec_idx,
        UNIFORM(1, 8, RANDOM()) AS reg_idx,
        CASE UNIFORM(1, 4, RANDOM())
            WHEN 1 THEN 'MD' WHEN 2 THEN 'DO' WHEN 3 THEN 'NP' ELSE 'PA'
        END AS cred_val,
        CASE UNIFORM(1, 20, RANDOM())
            WHEN 1 THEN 'TERMINATED' WHEN 2 THEN 'PENDING' ELSE 'ACTIVE'
        END AS status_val,
        DATEADD(DAY, -UNIFORM(365, 2555, RANDOM()), CURRENT_DATE()) AS contract_start_val
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT
    LPAD((1000000000 + b.row_id)::STRING, 10, '0') AS NPI,
    fn.name AS FIRST_NAME,
    ln.name AS LAST_NAME,
    b.cred_val AS CREDENTIAL,
    sp.spec AS SPECIALTY,
    NULL AS SUBSPECIALTY,
    fn.name || ' ' || ln.name || ' ' || sp.spec || ' Associates' AS PRACTICE_NAME,
    CASE UNIFORM(1, 3, RANDOM()) WHEN 1 THEN 'Solo' WHEN 2 THEN 'Group' ELSE 'Hospital-Based' END AS PRACTICE_TYPE,
    UNIFORM(100, 9999, RANDOM())::STRING || ' Medical Dr' AS ADDRESS,
    CASE b.reg_idx
        WHEN 1 THEN 'New York' WHEN 2 THEN 'Atlanta' WHEN 3 THEN 'Chicago'
        WHEN 4 THEN 'Houston' WHEN 5 THEN 'Los Angeles' WHEN 6 THEN 'Denver'
        WHEN 7 THEN 'Philadelphia' ELSE 'Seattle'
    END AS CITY,
    CASE b.reg_idx
        WHEN 1 THEN 'NY' WHEN 2 THEN 'GA' WHEN 3 THEN 'IL' WHEN 4 THEN 'TX'
        WHEN 5 THEN 'CA' WHEN 6 THEN 'CO' WHEN 7 THEN 'PA' ELSE 'WA'
    END AS STATE,
    CASE b.reg_idx
        WHEN 1 THEN '10001' WHEN 2 THEN '30301' WHEN 3 THEN '60601' WHEN 4 THEN '77001'
        WHEN 5 THEN '90001' WHEN 6 THEN '80201' WHEN 7 THEN '19101' ELSE '98101'
    END AS ZIP,
    r.REGION_ID,
    b.status_val AS CONTRACT_STATUS,
    b.contract_start_val AS CONTRACT_START,
    CASE WHEN b.status_val = 'TERMINATED' THEN FALSE ELSE TRUE END AS IS_ACTIVE
FROM base b
JOIN first_names fn ON fn.rn = b.fn_idx
JOIN last_names ln ON ln.rn = b.ln_idx
JOIN specialties sp ON sp.rn = b.spec_idx
JOIN regions r ON r.rn = b.reg_idx;

-- =============================================================================
-- 7. DIM_DIAGNOSIS_ICD10 — ~100 common ICD-10 codes
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.CLAIMS.DIM_DIAGNOSIS_ICD10;

INSERT INTO PAYER360_CUR.CLAIMS.DIM_DIAGNOSIS_ICD10
    (ICD10_CODE, DESCRIPTION, CHAPTER, CHAPTER_DESC, CATEGORY, IS_CHRONIC)
VALUES
    ('E11.9',  'Type 2 diabetes mellitus without complications',         'E',  'Endocrine/Metabolic', 'Diabetes',       TRUE),
    ('E11.65', 'Type 2 DM with hyperglycemia',                          'E',  'Endocrine/Metabolic', 'Diabetes',       TRUE),
    ('E11.21', 'Type 2 DM with diabetic nephropathy',                   'E',  'Endocrine/Metabolic', 'Diabetes',       TRUE),
    ('E78.5',  'Hyperlipidemia unspecified',                             'E',  'Endocrine/Metabolic', 'Metabolic',      TRUE),
    ('E03.9',  'Hypothyroidism unspecified',                             'E',  'Endocrine/Metabolic', 'Thyroid',        TRUE),
    ('I10',    'Essential hypertension',                                  'I',  'Circulatory',         'Hypertension',   TRUE),
    ('I25.10', 'Atherosclerotic heart disease native coronary artery',   'I',  'Circulatory',         'Cardiovascular', TRUE),
    ('I48.91', 'Unspecified atrial fibrillation',                        'I',  'Circulatory',         'Cardiovascular', TRUE),
    ('I50.9',  'Heart failure unspecified',                              'I',  'Circulatory',         'Cardiovascular', TRUE),
    ('I63.9',  'Cerebral infarction unspecified',                        'I',  'Circulatory',         'Cerebrovascular',FALSE),
    ('J44.1',  'COPD with acute exacerbation',                           'J',  'Respiratory',         'COPD',           TRUE),
    ('J44.0',  'COPD with acute lower respiratory infection',            'J',  'Respiratory',         'COPD',           TRUE),
    ('J45.20', 'Mild intermittent asthma uncomplicated',                 'J',  'Respiratory',         'Asthma',         TRUE),
    ('J45.40', 'Moderate persistent asthma uncomplicated',               'J',  'Respiratory',         'Asthma',         TRUE),
    ('J18.9',  'Pneumonia organism unspecified',                         'J',  'Respiratory',         'Infectious',     FALSE),
    ('J06.9',  'Acute upper respiratory infection unspecified',           'J',  'Respiratory',         'Infectious',     FALSE),
    ('K21.0',  'GERD with esophagitis',                                  'K',  'Digestive',           'GI',             TRUE),
    ('K80.20', 'Calculus of gallbladder without cholecystitis',          'K',  'Digestive',           'GI',             FALSE),
    ('K57.30', 'Diverticulosis of large intestine without hemorrhage',   'K',  'Digestive',           'GI',             TRUE),
    ('M54.5',  'Low back pain',                                          'M',  'Musculoskeletal',     'Pain',           TRUE),
    ('M17.11', 'Primary osteoarthritis right knee',                      'M',  'Musculoskeletal',     'Arthritis',      TRUE),
    ('M79.3',  'Panniculitis unspecified',                               'M',  'Musculoskeletal',     'Pain',           FALSE),
    ('M81.0',  'Age-related osteoporosis without pathological fracture', 'M',  'Musculoskeletal',     'Bone',           TRUE),
    ('G47.33', 'Obstructive sleep apnea',                                'G',  'Nervous System',      'Sleep',          TRUE),
    ('G43.909','Migraine unspecified not intractable',                    'G',  'Nervous System',      'Neurological',   TRUE),
    ('F32.1',  'Major depressive disorder single episode moderate',      'F',  'Mental Health',       'Depression',     TRUE),
    ('F41.1',  'Generalized anxiety disorder',                           'F',  'Mental Health',       'Anxiety',        TRUE),
    ('F10.20', 'Alcohol dependence uncomplicated',                       'F',  'Mental Health',       'Substance Use',  TRUE),
    ('N18.3',  'Chronic kidney disease stage 3',                         'N',  'Genitourinary',       'Kidney',         TRUE),
    ('N39.0',  'Urinary tract infection site not specified',             'N',  'Genitourinary',       'Infectious',     FALSE),
    ('C50.911','Malignant neoplasm unspecified site right female breast', 'C',  'Neoplasms',           'Cancer',         TRUE),
    ('C34.90', 'Malignant neoplasm unspecified part unspecified bronchus','C',  'Neoplasms',           'Cancer',         TRUE),
    ('C61',    'Malignant neoplasm of prostate',                         'C',  'Neoplasms',           'Cancer',         TRUE),
    ('D64.9',  'Anemia unspecified',                                     'D',  'Blood',               'Hematologic',    FALSE),
    ('R10.9',  'Unspecified abdominal pain',                             'R',  'Symptoms/Signs',      'GI',             FALSE),
    ('R05.9',  'Cough unspecified',                                      'R',  'Symptoms/Signs',      'Respiratory',    FALSE),
    ('R51.9',  'Headache unspecified',                                   'R',  'Symptoms/Signs',      'Neurological',   FALSE),
    ('S72.001A','Fracture of unspecified part of neck of right femur',   'S',  'Injury',              'Fracture',       FALSE),
    ('S82.001A','Fracture of right patella initial encounter',           'S',  'Injury',              'Fracture',       FALSE),
    ('Z23',    'Encounter for immunization',                             'Z',  'Factors',             'Preventive',     FALSE),
    ('Z00.00', 'Encounter for general adult medical exam without findings','Z','Factors',             'Preventive',     FALSE),
    ('Z12.31', 'Encounter for screening mammogram for malignant neoplasm','Z', 'Factors',             'Screening',      FALSE),
    ('Z87.891','Personal history of nicotine dependence',                 'Z', 'Factors',             'History',        FALSE),
    ('B34.9',  'Viral infection unspecified',                             'B', 'Infectious',          'Infectious',     FALSE),
    ('L40.0',  'Psoriasis vulgaris',                                     'L', 'Skin',                'Dermatologic',   TRUE),
    ('L30.9',  'Dermatitis unspecified',                                  'L', 'Skin',                'Dermatologic',   FALSE),
    ('T78.40', 'Allergy unspecified initial encounter',                   'T', 'Injury',              'Allergy',        FALSE),
    ('Z96.641','Presence of right artificial hip joint',                  'Z', 'Factors',             'Post-Surgical',  FALSE),
    ('E66.01', 'Morbid obesity due to excess calories',                  'E', 'Endocrine/Metabolic', 'Obesity',        TRUE),
    ('R73.03', 'Prediabetes',                                            'R', 'Symptoms/Signs',      'Metabolic',      FALSE);

-- =============================================================================
-- 8. DIM_PROCEDURE_CPT — ~80 common CPT codes
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.CLAIMS.DIM_PROCEDURE_CPT;

INSERT INTO PAYER360_CUR.CLAIMS.DIM_PROCEDURE_CPT
    (CPT_CODE, DESCRIPTION, CATEGORY, SUBCATEGORY, FEE_SCHEDULE_AMT, REQUIRES_AUTH)
VALUES
    -- E&M Codes
    ('99211', 'Office visit established patient minimal',      'E&M',        'Office Visit',   45.00,   FALSE),
    ('99212', 'Office visit established patient low',          'E&M',        'Office Visit',   75.00,   FALSE),
    ('99213', 'Office visit established patient moderate',     'E&M',        'Office Visit',   110.00,  FALSE),
    ('99214', 'Office visit established patient high',         'E&M',        'Office Visit',   165.00,  FALSE),
    ('99215', 'Office visit established patient comprehensive','E&M',        'Office Visit',   225.00,  FALSE),
    ('99201', 'Office visit new patient minimal',              'E&M',        'Office Visit',   65.00,   FALSE),
    ('99203', 'Office visit new patient moderate',             'E&M',        'Office Visit',   150.00,  FALSE),
    ('99205', 'Office visit new patient comprehensive',        'E&M',        'Office Visit',   275.00,  FALSE),
    ('99281', 'ED visit minimal',                              'E&M',        'Emergency',      85.00,   FALSE),
    ('99283', 'ED visit moderate',                             'E&M',        'Emergency',      250.00,  FALSE),
    ('99285', 'ED visit high severity',                        'E&M',        'Emergency',      650.00,  FALSE),
    -- Surgery
    ('27447', 'Total knee arthroplasty',                       'Surgery',    'Orthopedic',     15000.00,TRUE),
    ('27130', 'Total hip arthroplasty',                        'Surgery',    'Orthopedic',     14500.00,TRUE),
    ('47562', 'Laparoscopic cholecystectomy',                  'Surgery',    'General',        5500.00, TRUE),
    ('44970', 'Laparoscopic appendectomy',                     'Surgery',    'General',        4200.00, TRUE),
    ('33533', 'CABG single arterial graft',                    'Surgery',    'Cardiac',        25000.00,TRUE),
    ('33208', 'Insertion of pacemaker',                        'Surgery',    'Cardiac',        12000.00,TRUE),
    ('19301', 'Partial mastectomy',                            'Surgery',    'Oncologic',      6500.00, TRUE),
    ('43239', 'Upper GI endoscopy with biopsy',                'Surgery',    'GI',             1200.00, TRUE),
    ('45380', 'Colonoscopy with biopsy',                       'Surgery',    'GI',             1500.00, FALSE),
    ('45378', 'Diagnostic colonoscopy',                        'Surgery',    'GI',             1100.00, FALSE),
    -- Radiology
    ('71046', 'Chest X-ray 2 views',                           'Radiology',  'Diagnostic',     85.00,   FALSE),
    ('74177', 'CT abdomen and pelvis with contrast',           'Radiology',  'Diagnostic',     750.00,  FALSE),
    ('70553', 'MRI brain with and without contrast',           'Radiology',  'Diagnostic',     1200.00, TRUE),
    ('77067', 'Screening mammography bilateral',               'Radiology',  'Screening',      225.00,  FALSE),
    ('72148', 'MRI lumbar spine without contrast',             'Radiology',  'Diagnostic',     950.00,  TRUE),
    ('73721', 'MRI lower extremity joint without contrast',    'Radiology',  'Diagnostic',     850.00,  TRUE),
    -- Lab
    ('80053', 'Comprehensive metabolic panel',                 'Lab',        'Chemistry',      50.00,   FALSE),
    ('80061', 'Lipid panel',                                   'Lab',        'Chemistry',      45.00,   FALSE),
    ('85025', 'Complete blood count with differential',         'Lab',        'Hematology',     35.00,   FALSE),
    ('83036', 'Hemoglobin A1c',                                'Lab',        'Chemistry',      55.00,   FALSE),
    ('81001', 'Urinalysis with microscopy',                    'Lab',        'Urinalysis',     25.00,   FALSE),
    ('84443', 'TSH level',                                     'Lab',        'Chemistry',      60.00,   FALSE),
    ('82607', 'Vitamin B-12 level',                            'Lab',        'Chemistry',      65.00,   FALSE),
    ('82306', 'Vitamin D 25-hydroxy',                          'Lab',        'Chemistry',      70.00,   FALSE),
    -- Physical Therapy
    ('97110', 'Therapeutic exercises 15 min',                   'Therapy',    'Physical',       65.00,   FALSE),
    ('97140', 'Manual therapy techniques 15 min',              'Therapy',    'Physical',       70.00,   FALSE),
    ('97530', 'Therapeutic activities 15 min',                  'Therapy',    'Physical',       60.00,   FALSE),
    -- Mental Health
    ('90834', 'Psychotherapy 45 minutes',                      'Mental Health','Therapy',      120.00,  FALSE),
    ('90837', 'Psychotherapy 60 minutes',                      'Mental Health','Therapy',      160.00,  FALSE),
    ('90847', 'Family psychotherapy with patient',             'Mental Health','Therapy',      150.00,  FALSE),
    -- Preventive
    ('99395', 'Preventive visit established 18-39',            'Preventive', 'Annual',         200.00,  FALSE),
    ('99396', 'Preventive visit established 40-64',            'Preventive', 'Annual',         220.00,  FALSE),
    ('99397', 'Preventive visit established 65+',              'Preventive', 'Annual',         240.00,  FALSE),
    ('90715', 'Tdap vaccine administration',                   'Preventive', 'Immunization',   45.00,   FALSE),
    ('90662', 'Influenza vaccine high-dose',                   'Preventive', 'Immunization',   75.00,   FALSE),
    -- Other
    ('93000', 'Electrocardiogram complete',                    'Cardiology', 'Diagnostic',     85.00,   FALSE),
    ('93306', 'Echocardiography complete',                     'Cardiology', 'Diagnostic',     450.00,  FALSE),
    ('93452', 'Left heart catheterization',                    'Cardiology', 'Interventional', 3500.00, TRUE),
    ('36415', 'Venipuncture routine',                          'Lab',        'Collection',     15.00,   FALSE);
