-- =============================================================================
-- Payer360 Demo: Seed Fact Tables with Synthetic Data
-- =============================================================================
-- Run as: SYSADMIN on P360_LOAD_WH
-- Prerequisite: 04_facts.sql executed (tables exist, empty), dimensions seeded
-- Scale: 800K claims, 600K premiums, 100K enrollments, 50K surveys, 5K contracts,
--        15K grievances, 200K authorizations
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE P360_LOAD_WH;

-- =============================================================================
-- 1. FCT_CLAIM — 800K claim lines with realistic adjudication workflow
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.CLAIMS.FCT_CLAIM;

INSERT INTO PAYER360_CUR.CLAIMS.FCT_CLAIM
    (CLAIM_ID, LINE_NUMBER, MEMBER_SK, PROVIDER_SK, DX_SK, PROC_SK,
     PLAN_SK, LOB_SK, SERVICE_DATE, SERVICE_DATE_KEY, RECEIVED_DATE,
     ADJUDICATED_DATE, PAID_DATE, CHARGE_AMT, ALLOWED_AMT, PAID_AMT,
     MEMBER_RESPONSIBILITY, IS_DENIED, DENIAL_REASON, DENIAL_CATEGORY,
     CLAIM_STATUS, IS_CLEAN_CLAIM, IS_AUTO_ADJUDICATED, IS_APPEALED,
     APPEAL_OUTCOME, PLACE_OF_SERVICE)
WITH base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        'CLM-' || LPAD(SEQ4()::STRING, 7, '0') AS claim_id,
        UNIFORM(1, 3, RANDOM()) AS line_number,
        UNIFORM(1, 50000, RANDOM()) AS member_sk,
        UNIFORM(1, 500, RANDOM()) AS provider_sk,
        UNIFORM(1, 100, RANDOM()) AS dx_sk,
        UNIFORM(1, 80, RANDOM()) AS proc_sk,
        UNIFORM(1, 20, RANDOM()) AS plan_sk,
        UNIFORM(1, 5, RANDOM()) AS lob_sk,
        DATEADD(DAY, UNIFORM(0, 730, RANDOM()), '2023-01-01'::DATE) AS svc_date,
        -- Denial flag: ~12% denial rate
        UNIFORM(1, 100, RANDOM()) AS deny_roll,
        -- Clean claim: ~75%
        UNIFORM(1, 100, RANDOM()) AS clean_roll,
        -- Auto-adjudicated: ~45%
        UNIFORM(1, 100, RANDOM()) AS auto_roll,
        -- Charge amount with realistic distribution
        ROUND(POWER(10, UNIFORM(150, 400, RANDOM()) / 100.0), 2) AS charge_amt,
        -- Place of service
        CASE UNIFORM(1, 6, RANDOM())
            WHEN 1 THEN '11' -- Office
            WHEN 2 THEN '21' -- Inpatient
            WHEN 3 THEN '22' -- Outpatient
            WHEN 4 THEN '23' -- ER
            WHEN 5 THEN '31' -- Skilled Nursing
            ELSE '81'        -- Lab
        END AS pos,
        -- Random seeds for downstream calcs
        UNIFORM(60, 95, RANDOM()) AS allowed_pct,
        UNIFORM(80, 100, RANDOM()) AS paid_pct,
        UNIFORM(1, 5, RANDOM()) AS recv_delay,
        UNIFORM(3, 7, RANDOM()) AS clean_adj_days,
        UNIFORM(10, 45, RANDOM()) AS dirty_adj_days,
        UNIFORM(5, 15, RANDOM()) AS pay_delay,
        UNIFORM(1, 100, RANDOM()) AS appeal_roll,
        UNIFORM(1, 100, RANDOM()) AS appeal_outcome_roll,
        -- Denial reason weighting
        UNIFORM(1, 100, RANDOM()) AS denial_reason_roll
    FROM TABLE(GENERATOR(ROWCOUNT => 800000))
),
computed AS (
    SELECT
        *,
        TO_NUMBER(TO_CHAR(svc_date, 'YYYYMMDD')) AS svc_date_key,
        DATEADD(DAY, recv_delay, svc_date) AS received_date,
        (deny_roll <= 12) AS is_denied,
        (clean_roll <= 75) AS is_clean,
        (auto_roll <= 45) AS is_auto,
        ROUND(charge_amt * allowed_pct / 100.0, 2) AS allowed_amt,
        CASE WHEN clean_roll <= 75 THEN clean_adj_days ELSE dirty_adj_days END AS days_to_adj
    FROM base
),
final AS (
    SELECT
        *,
        ROUND(allowed_amt * paid_pct / 100.0, 2) AS paid_amt_calc,
        ROUND(allowed_amt * (1.0 - paid_pct / 100.0), 2) AS member_resp,
        DATEADD(DAY, days_to_adj, received_date) AS adj_date,
        DATEADD(DAY, pay_delay, DATEADD(DAY, days_to_adj, received_date)) AS pay_date
    FROM computed
)
SELECT
    claim_id,
    line_number,
    member_sk,
    provider_sk,
    dx_sk,
    proc_sk,
    plan_sk,
    lob_sk,
    svc_date AS SERVICE_DATE,
    svc_date_key AS SERVICE_DATE_KEY,
    received_date AS RECEIVED_DATE,
    adj_date AS ADJUDICATED_DATE,
    CASE WHEN is_denied THEN NULL ELSE pay_date END AS PAID_DATE,
    charge_amt AS CHARGE_AMT,
    CASE WHEN is_denied THEN 0 ELSE allowed_amt END AS ALLOWED_AMT,
    CASE WHEN is_denied THEN 0 ELSE paid_amt_calc END AS PAID_AMT,
    CASE WHEN is_denied THEN 0 ELSE member_resp END AS MEMBER_RESPONSIBILITY,
    is_denied AS IS_DENIED,
    -- Denial reason with weighted distribution
    CASE WHEN is_denied THEN
        CASE
            WHEN denial_reason_roll <= 25 THEN 'Medical Necessity Not Met'
            WHEN denial_reason_roll <= 40 THEN 'Prior Authorization Required'
            WHEN denial_reason_roll <= 55 THEN 'Out of Network'
            WHEN denial_reason_roll <= 65 THEN 'Duplicate Claim'
            WHEN denial_reason_roll <= 75 THEN 'Timely Filing Exceeded'
            WHEN denial_reason_roll <= 82 THEN 'Invalid Coding'
            WHEN denial_reason_roll <= 88 THEN 'Coverage Terminated'
            WHEN denial_reason_roll <= 93 THEN 'Pre-existing Condition'
            WHEN denial_reason_roll <= 97 THEN 'Non-covered Service'
            ELSE 'Coordination of Benefits'
        END
    ELSE NULL END AS DENIAL_REASON,
    CASE WHEN is_denied THEN
        CASE
            WHEN denial_reason_roll <= 25 THEN 'Clinical'
            WHEN denial_reason_roll <= 40 THEN 'Administrative'
            WHEN denial_reason_roll <= 55 THEN 'Coverage'
            WHEN denial_reason_roll <= 65 THEN 'Duplicate'
            WHEN denial_reason_roll <= 75 THEN 'Administrative'
            WHEN denial_reason_roll <= 82 THEN 'Administrative'
            WHEN denial_reason_roll <= 88 THEN 'Coverage'
            WHEN denial_reason_roll <= 93 THEN 'Coverage'
            WHEN denial_reason_roll <= 97 THEN 'Coverage'
            ELSE 'Administrative'
        END
    ELSE NULL END AS DENIAL_CATEGORY,
    -- Claim status
    CASE
        WHEN is_denied AND appeal_roll <= 30 THEN 'APPEALED'
        WHEN is_denied THEN 'DENIED'
        ELSE 'PAID'
    END AS CLAIM_STATUS,
    is_clean AS IS_CLEAN_CLAIM,
    is_auto AS IS_AUTO_ADJUDICATED,
    -- Appeal logic: only denied claims, 30% chance
    CASE WHEN is_denied AND appeal_roll <= 30 THEN TRUE ELSE FALSE END AS IS_APPEALED,
    -- Appeal outcome: 40% WON, 35% LOST, 25% PENDING
    CASE
        WHEN is_denied AND appeal_roll <= 30 THEN
            CASE
                WHEN appeal_outcome_roll <= 40 THEN 'UPHELD'
                WHEN appeal_outcome_roll <= 75 THEN 'OVERTURNED'
                ELSE 'PENDING'
            END
        ELSE NULL
    END AS APPEAL_OUTCOME,
    pos AS PLACE_OF_SERVICE
FROM final;

-- =============================================================================
-- 2. FCT_PREMIUM — 600K member-month premium records
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.FINANCIAL.FCT_PREMIUM;

INSERT INTO PAYER360_CUR.FINANCIAL.FCT_PREMIUM
    (MEMBER_SK, PLAN_SK, LOB_SK, PREMIUM_MONTH, PREMIUM_DATE_KEY,
     PREMIUM_EARNED, INCURRED_CLAIMS_AMT, QUALITY_IMPROVEMENT_AMT, ADMIN_EXPENSE_AMT)
WITH base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        UNIFORM(1, 50000, RANDOM()) AS member_sk,
        UNIFORM(1, 20, RANDOM()) AS plan_sk,
        UNIFORM(1, 5, RANDOM()) AS lob_sk,
        -- Spread across 24 months (2023-01 through 2024-12)
        DATEADD(MONTH, MOD(SEQ4(), 24), '2023-01-01'::DATE) AS premium_month,
        UNIFORM(250, 1200, RANDOM()) AS premium_earned,
        UNIFORM(65, 95, RANDOM()) AS incurred_pct,
        UNIFORM(3, 5, RANDOM()) AS qi_pct,
        UNIFORM(12, 18, RANDOM()) AS admin_pct
    FROM TABLE(GENERATOR(ROWCOUNT => 600000))
)
SELECT
    member_sk,
    plan_sk,
    lob_sk,
    premium_month,
    TO_NUMBER(TO_CHAR(premium_month, 'YYYYMMDD')) AS PREMIUM_DATE_KEY,
    ROUND(premium_earned, 2) AS PREMIUM_EARNED,
    ROUND(premium_earned * incurred_pct / 100.0, 2) AS INCURRED_CLAIMS_AMT,
    ROUND(premium_earned * qi_pct / 100.0, 2) AS QUALITY_IMPROVEMENT_AMT,
    ROUND(premium_earned * admin_pct / 100.0, 2) AS ADMIN_EXPENSE_AMT
FROM base;

-- =============================================================================
-- 3. FCT_ENROLLMENT — 100K enrollment lifecycle events
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.MEMBERSHIP.FCT_ENROLLMENT;

INSERT INTO PAYER360_CUR.MEMBERSHIP.FCT_ENROLLMENT
    (MEMBER_SK, PLAN_SK, LOB_SK, EVENT_TYPE, EVENT_DATE, EVENT_DATE_KEY,
     EFFECTIVE_DATE, TERM_DATE, TERM_REASON, PRIOR_PLAN_SK)
WITH base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        UNIFORM(1, 50000, RANDOM()) AS member_sk,
        UNIFORM(1, 20, RANDOM()) AS plan_sk,
        UNIFORM(1, 5, RANDOM()) AS lob_sk,
        -- Event type weighted: ENROLL 40%, RENEW 45%, TERM 10%, TRANSFER 5%
        UNIFORM(1, 100, RANDOM()) AS event_roll,
        DATEADD(DAY, UNIFORM(0, 730, RANDOM()), '2023-01-01'::DATE) AS event_date,
        UNIFORM(1, 100, RANDOM()) AS term_reason_roll,
        UNIFORM(1, 20, RANDOM()) AS prior_plan_sk
    FROM TABLE(GENERATOR(ROWCOUNT => 100000))
),
typed AS (
    SELECT
        *,
        CASE
            WHEN event_roll <= 40 THEN 'ENROLL'
            WHEN event_roll <= 85 THEN 'RENEW'
            WHEN event_roll <= 95 THEN 'TERM'
            ELSE 'TRANSFER'
        END AS event_type
    FROM base
)
SELECT
    member_sk,
    plan_sk,
    lob_sk,
    event_type,
    event_date,
    TO_NUMBER(TO_CHAR(event_date, 'YYYYMMDD')) AS EVENT_DATE_KEY,
    -- Effective date is first of next month for new enrollments
    CASE
        WHEN event_type = 'ENROLL' THEN DATE_TRUNC('MONTH', DATEADD(MONTH, 1, event_date))
        ELSE event_date
    END AS EFFECTIVE_DATE,
    -- Term date only for TERM events
    CASE WHEN event_type = 'TERM' THEN LAST_DAY(event_date, 'MONTH') ELSE NULL END AS TERM_DATE,
    -- Term reason weighted distribution
    CASE WHEN event_type = 'TERM' THEN
        CASE
            WHEN term_reason_roll <= 40 THEN 'VOLUNTARY'
            WHEN term_reason_roll <= 65 THEN 'NON_PAYMENT'
            WHEN term_reason_roll <= 80 THEN 'MOVED'
            WHEN term_reason_roll <= 92 THEN 'EMPLOYER_CHANGE'
            WHEN term_reason_roll <= 95 THEN 'DEATH'
            ELSE 'OTHER'
        END
    ELSE NULL END AS TERM_REASON,
    -- Prior plan only for TRANSFER events
    CASE WHEN event_type = 'TRANSFER' THEN prior_plan_sk ELSE NULL END AS PRIOR_PLAN_SK
FROM typed;

-- =============================================================================
-- 4. FCT_SURVEY — 50K member satisfaction responses
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.MEMBER_EXPERIENCE.FCT_SURVEY;

INSERT INTO PAYER360_CUR.MEMBER_EXPERIENCE.FCT_SURVEY
    (SURVEY_ID, MEMBER_SK, PLAN_SK, LOB_SK, SURVEY_DATE, SURVEY_DATE_KEY,
     NPS_SCORE, SATISFACTION_SCORE, TOPIC, CHANNEL)
WITH base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        'SVY-' || LPAD(SEQ4()::STRING, 6, '0') AS survey_id,
        UNIFORM(1, 50000, RANDOM()) AS member_sk,
        UNIFORM(1, 20, RANDOM()) AS plan_sk,
        UNIFORM(1, 5, RANDOM()) AS lob_sk,
        DATEADD(DAY, UNIFORM(0, 730, RANDOM()), '2023-01-01'::DATE) AS survey_date,
        -- NPS distribution: 0-6 (20%), 7-8 (30%), 9-10 (50%)
        UNIFORM(1, 100, RANDOM()) AS nps_roll,
        UNIFORM(1, 6, RANDOM()) AS topic_roll,
        UNIFORM(1, 4, RANDOM()) AS channel_roll
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
),
scored AS (
    SELECT
        *,
        CASE
            WHEN nps_roll <= 20 THEN UNIFORM(0, 6, RANDOM())
            WHEN nps_roll <= 50 THEN UNIFORM(7, 8, RANDOM())
            ELSE UNIFORM(9, 10, RANDOM())
        END AS nps_score
    FROM base
)
SELECT
    survey_id,
    member_sk,
    plan_sk,
    lob_sk,
    survey_date,
    TO_NUMBER(TO_CHAR(survey_date, 'YYYYMMDD')) AS SURVEY_DATE_KEY,
    nps_score AS NPS_SCORE,
    -- Satisfaction loosely correlated with NPS
    LEAST(10, GREATEST(1, nps_score + UNIFORM(-2, 1, RANDOM()))) AS SATISFACTION_SCORE,
    -- Topic random pick from 6 options
    CASE topic_roll
        WHEN 1 THEN 'Claims Processing'
        WHEN 2 THEN 'Customer Service'
        WHEN 3 THEN 'Provider Network'
        WHEN 4 THEN 'Coverage & Benefits'
        WHEN 5 THEN 'Billing & Payments'
        ELSE 'Digital Experience'
    END AS TOPIC,
    -- Channel
    CASE channel_roll
        WHEN 1 THEN 'Email'
        WHEN 2 THEN 'Phone'
        WHEN 3 THEN 'Web'
        ELSE 'App'
    END AS CHANNEL
FROM scored;

-- =============================================================================
-- 5. FCT_PROVIDER_CONTRACT — 5K provider contracts
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.NETWORK.FCT_PROVIDER_CONTRACT;

INSERT INTO PAYER360_CUR.NETWORK.FCT_PROVIDER_CONTRACT
    (PROVIDER_SK, REGION_SK, CONTRACT_START, CONTRACT_END, IS_ACTIVE, IS_TERMINATED,
     TERMINATION_REASON, FEE_SCHEDULE_TYPE, QUALITY_SCORE, CLAIMS_VOLUME, MEMBER_PANEL_SIZE)
WITH base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        UNIFORM(1, 500, RANDOM()) AS provider_sk,
        UNIFORM(1, 8, RANDOM()) AS region_sk,
        -- Contract start spread from 2018 to 2025
        DATEADD(DAY, UNIFORM(0, 2555, RANDOM()), '2018-01-01'::DATE) AS contract_start,
        -- ~8% terminated
        UNIFORM(1, 100, RANDOM()) AS term_roll,
        UNIFORM(1, 100, RANDOM()) AS term_reason_roll,
        -- Fee schedule type
        CASE UNIFORM(1, 4, RANDOM())
            WHEN 1 THEN 'STANDARD'
            WHEN 2 THEN 'CAPITATED'
            WHEN 3 THEN 'VALUE_BASED'
            ELSE 'BUNDLED'
        END AS fee_type,
        -- Quality score centered at 3.8 (on 0-5 scale)
        ROUND(GREATEST(2.0, LEAST(5.0, 3.8 + (UNIFORM(-20, 12, RANDOM()) / 10.0))), 2) AS quality_score,
        UNIFORM(50, 5000, RANDOM()) AS claims_volume,
        UNIFORM(100, 3000, RANDOM()) AS member_panel_size
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
),
computed AS (
    SELECT
        *,
        (term_roll <= 8) AS is_terminated
    FROM base
)
SELECT
    provider_sk,
    region_sk,
    contract_start,
    CASE WHEN is_terminated
         THEN DATEADD(DAY, UNIFORM(180, 1825, RANDOM()), contract_start)
         ELSE NULL
    END AS CONTRACT_END,
    NOT is_terminated AS IS_ACTIVE,
    is_terminated AS IS_TERMINATED,
    CASE WHEN is_terminated THEN
        CASE
            WHEN term_reason_roll <= 30 THEN 'VOLUNTARY_EXIT'
            WHEN term_reason_roll <= 50 THEN 'QUALITY_ISSUE'
            WHEN term_reason_roll <= 70 THEN 'CONTRACT_DISPUTE'
            WHEN term_reason_roll <= 85 THEN 'RELOCATION'
            ELSE 'RETIREMENT'
        END
    ELSE NULL END AS TERMINATION_REASON,
    fee_type AS FEE_SCHEDULE_TYPE,
    quality_score AS QUALITY_SCORE,
    claims_volume AS CLAIMS_VOLUME,
    member_panel_size AS MEMBER_PANEL_SIZE
FROM computed;

-- =============================================================================
-- 6. FCT_GRIEVANCE — 15K member grievances
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.MEMBER_EXPERIENCE.FCT_GRIEVANCE;

INSERT INTO PAYER360_CUR.MEMBER_EXPERIENCE.FCT_GRIEVANCE
    (GRIEVANCE_ID, MEMBER_SK, PLAN_SK, LOB_SK, FILED_DATE, FILED_DATE_KEY,
     CATEGORY, RESOLUTION_DATE, RESOLUTION_DAYS, STATUS)
WITH base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        'GRV-' || LPAD(SEQ4()::STRING, 6, '0') AS grievance_id,
        UNIFORM(1, 50000, RANDOM()) AS member_sk,
        UNIFORM(1, 20, RANDOM()) AS plan_sk,
        UNIFORM(1, 5, RANDOM()) AS lob_sk,
        DATEADD(DAY, UNIFORM(0, 730, RANDOM()), '2023-01-01'::DATE) AS filed_date,
        -- Category weighted distribution
        UNIFORM(1, 100, RANDOM()) AS cat_roll,
        -- Resolution days
        UNIFORM(5, 45, RANDOM()) AS resolution_days,
        -- Status: RESOLVED 80%, PENDING 15%, ESCALATED 5%
        UNIFORM(1, 100, RANDOM()) AS status_roll
    FROM TABLE(GENERATOR(ROWCOUNT => 15000))
),
typed AS (
    SELECT
        *,
        CASE
            WHEN cat_roll <= 30 THEN 'Billing Dispute'
            WHEN cat_roll <= 50 THEN 'Access to Care'
            WHEN cat_roll <= 65 THEN 'Quality of Care'
            WHEN cat_roll <= 78 THEN 'Communication'
            WHEN cat_roll <= 88 THEN 'Claims Processing'
            WHEN cat_roll <= 95 THEN 'Coverage Denial'
            ELSE 'Other'
        END AS category,
        CASE
            WHEN status_roll <= 80 THEN 'RESOLVED'
            WHEN status_roll <= 95 THEN 'PENDING'
            ELSE 'ESCALATED'
        END AS status
    FROM base
)
SELECT
    grievance_id,
    member_sk,
    plan_sk,
    lob_sk,
    filed_date,
    TO_NUMBER(TO_CHAR(filed_date, 'YYYYMMDD')) AS FILED_DATE_KEY,
    category,
    CASE WHEN status = 'RESOLVED'
         THEN DATEADD(DAY, resolution_days, filed_date)
         ELSE NULL
    END AS RESOLUTION_DATE,
    CASE WHEN status = 'RESOLVED' THEN resolution_days ELSE NULL END AS RESOLUTION_DAYS,
    status AS STATUS
FROM typed;

-- =============================================================================
-- 7. FCT_AUTHORIZATION — 200K prior authorization requests
-- =============================================================================
TRUNCATE TABLE IF EXISTS PAYER360_CUR.CLAIMS.FCT_AUTHORIZATION;

INSERT INTO PAYER360_CUR.CLAIMS.FCT_AUTHORIZATION
    (AUTH_ID, MEMBER_SK, PROVIDER_SK, PROC_SK, PLAN_SK, LOB_SK,
     REQUEST_DATE, REQUEST_DATE_KEY, DECISION_DATE, DECISION,
     DENIAL_REASON, DAYS_TO_DECIDE, IS_EXPEDITED)
WITH base AS (
    SELECT
        SEQ4() + 1 AS row_id,
        'AUTH-' || LPAD(SEQ4()::STRING, 6, '0') AS auth_id,
        UNIFORM(1, 50000, RANDOM()) AS member_sk,
        UNIFORM(1, 500, RANDOM()) AS provider_sk,
        UNIFORM(1, 80, RANDOM()) AS proc_sk,
        UNIFORM(1, 20, RANDOM()) AS plan_sk,
        UNIFORM(1, 5, RANDOM()) AS lob_sk,
        DATEADD(DAY, UNIFORM(0, 730, RANDOM()), '2023-01-01'::DATE) AS request_date,
        -- Decision: APPROVED 70%, DENIED 20%, PARTIAL 10%
        UNIFORM(1, 100, RANDOM()) AS decision_roll,
        -- IS_EXPEDITED: 15%
        UNIFORM(1, 100, RANDOM()) AS expedite_roll,
        -- Days to decide: expedited 1-3, standard 3-14
        UNIFORM(1, 3, RANDOM()) AS exp_days,
        UNIFORM(3, 14, RANDOM()) AS std_days,
        -- Denial reason for denied
        UNIFORM(1, 100, RANDOM()) AS deny_reason_roll
    FROM TABLE(GENERATOR(ROWCOUNT => 200000))
),
typed AS (
    SELECT
        *,
        CASE
            WHEN decision_roll <= 70 THEN 'APPROVED'
            WHEN decision_roll <= 90 THEN 'DENIED'
            ELSE 'PARTIAL'
        END AS decision,
        (expedite_roll <= 15) AS is_expedited,
        CASE WHEN expedite_roll <= 15 THEN exp_days ELSE std_days END AS days_to_decide
    FROM base
)
SELECT
    auth_id,
    member_sk,
    provider_sk,
    proc_sk,
    plan_sk,
    lob_sk,
    request_date,
    TO_NUMBER(TO_CHAR(request_date, 'YYYYMMDD')) AS REQUEST_DATE_KEY,
    DATEADD(DAY, days_to_decide, request_date) AS DECISION_DATE,
    decision AS DECISION,
    CASE WHEN decision = 'DENIED' THEN
        CASE
            WHEN deny_reason_roll <= 35 THEN 'Medical Necessity Not Met'
            WHEN deny_reason_roll <= 55 THEN 'Insufficient Documentation'
            WHEN deny_reason_roll <= 70 THEN 'Out of Network'
            WHEN deny_reason_roll <= 82 THEN 'Experimental/Investigational'
            WHEN deny_reason_roll <= 92 THEN 'Non-covered Service'
            ELSE 'Exhausted Benefit Limit'
        END
    ELSE NULL END AS DENIAL_REASON,
    days_to_decide AS DAYS_TO_DECIDE,
    is_expedited AS IS_EXPEDITED
FROM typed;
