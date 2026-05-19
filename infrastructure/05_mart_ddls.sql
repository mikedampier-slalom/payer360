-- =============================================================================
-- Payer360 Demo: Use-Case Mart DDLs
-- =============================================================================
-- Run as: SYSADMIN
-- Prerequisite: 03_dimensions.sql, 04_facts.sql, seed scripts executed
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE P360_XFM_WH;

-- =============================================================================
-- MART_MEDICAL_LOSS_RATIO — MLR analysis by LOB and month
-- Grain: 1 row per line-of-business per month
-- Schema: PAYER360_CUR.FINANCIAL
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.FINANCIAL.MART_MEDICAL_LOSS_RATIO (
    LOB_ID                    STRING(10)    NOT NULL,
    LOB_NAME                  STRING(50)    NOT NULL,
    MLR_THRESHOLD             FLOAT         NOT NULL,
    PERIOD_DATE               DATE          NOT NULL,  -- first of month
    PREMIUM_EARNED            FLOAT         NOT NULL,
    INCURRED_CLAIMS           FLOAT         NOT NULL,
    QUALITY_IMPROVEMENT_EXPENSE FLOAT,
    ADMIN_EXPENSE             FLOAT,
    MLR_PCT                   FLOAT         NOT NULL,  -- (claims + QI) / premium
    ADMIN_RATIO_PCT           FLOAT,
    IS_COMPLIANT              BOOLEAN,       -- MLR_PCT >= MLR_THRESHOLD
    MEMBER_MONTHS             INTEGER,
    PRIMARY KEY (LOB_ID, PERIOD_DATE)
)
COMMENT = 'MLR mart: line-of-business monthly Medical Loss Ratio with ACA compliance flag';

-- =============================================================================
-- MART_CLAIMS_DENIALS — Claim denial detail
-- Grain: 1 row per claim line
-- Schema: PAYER360_CUR.CLAIMS
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.CLAIMS.MART_CLAIMS_DENIALS (
    CLAIM_ID                  STRING(20)    NOT NULL,
    LINE_NUMBER               INTEGER       NOT NULL,
    MEMBER_ID                 STRING(20)    NOT NULL,
    MEMBER_NAME               STRING(100),
    PROVIDER_NPI              STRING(10),
    PROVIDER_NAME             STRING(100),
    SPECIALTY                 STRING(50),
    SERVICE_DATE              DATE          NOT NULL,
    SERVICE_MONTH             DATE,
    CHARGE_AMT                FLOAT         NOT NULL,
    ALLOWED_AMT               FLOAT,
    DENIAL_REASON             STRING(50),
    DENIAL_CATEGORY           STRING(30),
    IS_DENIED                 BOOLEAN       NOT NULL,
    CLAIM_STATUS              STRING(20),
    IS_APPEALED               BOOLEAN,
    APPEAL_OUTCOME            STRING(20),
    LINE_OF_BUSINESS          STRING(30),
    PLAN_TYPE                 STRING(10),
    CPT_CODE                  STRING(10),
    CPT_DESCRIPTION           STRING(255),
    ICD10_CODE                STRING(10),
    DX_DESCRIPTION            STRING(255),
    PRIMARY KEY (CLAIM_ID, LINE_NUMBER)
)
COMMENT = 'Claims Denials mart: claim-line detail with denial reason analysis and appeal tracking';

-- =============================================================================
-- MART_MEMBER_RENEWALS — Member retention and renewal analysis
-- Grain: 1 row per member-policy-period
-- Schema: PAYER360_CUR.MEMBERSHIP
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.MEMBERSHIP.MART_MEMBER_RENEWALS (
    MEMBER_ID                 STRING(20)    NOT NULL,
    MEMBER_NAME               STRING(100),
    PLAN_ID                   STRING(20)    NOT NULL,
    PLAN_NAME                 STRING(100),
    PLAN_TYPE                 STRING(10),
    LINE_OF_BUSINESS          STRING(30),
    EFFECTIVE_DATE            DATE          NOT NULL,
    TERM_DATE                 DATE,
    RENEWAL_FLAG              BOOLEAN,
    LAPSE_FLAG                BOOLEAN,
    TENURE_MONTHS             INTEGER,
    PREMIUM_MONTHLY           FLOAT,
    RISK_SCORE                FLOAT,
    AGE                       INTEGER,
    GENDER                    STRING(10),
    REGION                    STRING(50),
    PRIMARY KEY (MEMBER_ID, PLAN_ID, EFFECTIVE_DATE)
)
COMMENT = 'Member Renewals mart: member-policy renewal/lapse analysis with tenure and demographics';

-- =============================================================================
-- MART_MEMBER_SATISFACTION — Member experience and NPS
-- Grain: 1 row per survey response
-- Schema: PAYER360_CUR.MEMBER_EXPERIENCE
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.MEMBER_EXPERIENCE.MART_MEMBER_SATISFACTION (
    SURVEY_ID                 STRING(20)    NOT NULL,
    MEMBER_ID                 STRING(20)    NOT NULL,
    MEMBER_NAME               STRING(100),
    SURVEY_DATE               DATE          NOT NULL,
    SURVEY_MONTH              DATE,
    NPS_SCORE                 INTEGER,
    NPS_CATEGORY              STRING(10),   -- PROMOTER, PASSIVE, DETRACTOR
    SATISFACTION_SCORE        INTEGER,
    TOPIC                     STRING(50),
    PLAN_TYPE                 STRING(10),
    LINE_OF_BUSINESS          STRING(30),
    IS_GRIEVANCE              BOOLEAN,
    RESOLUTION_DAYS           INTEGER,
    MEMBER_TENURE_MONTHS      INTEGER,
    PRIMARY KEY (SURVEY_ID)
)
COMMENT = 'Member Satisfaction mart: NPS and CSAT with grievance correlation';

-- =============================================================================
-- MART_COMBINED_RATIO — Insurance combined ratio by LOB and quarter
-- Grain: 1 row per line-of-business per quarter
-- Schema: PAYER360_CUR.FINANCIAL
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.FINANCIAL.MART_COMBINED_RATIO (
    LOB_ID                    STRING(10)    NOT NULL,
    LOB_NAME                  STRING(50)    NOT NULL,
    QUARTER_DATE              DATE          NOT NULL,  -- first of quarter
    QUARTER_LABEL             STRING(7),    -- e.g. '2024-Q3'
    PREMIUM_EARNED            FLOAT         NOT NULL,
    INCURRED_LOSSES           FLOAT         NOT NULL,
    LOSS_ADJUSTMENT_EXPENSE   FLOAT,
    UNDERWRITING_EXPENSE      FLOAT,
    LOSS_RATIO_PCT            FLOAT         NOT NULL,
    EXPENSE_RATIO_PCT         FLOAT,
    COMBINED_RATIO_PCT        FLOAT         NOT NULL,  -- loss + expense ratio
    UNDERWRITING_RESULT       FLOAT,         -- premium - losses - expenses
    MEMBER_COUNT              INTEGER,
    PRIMARY KEY (LOB_ID, QUARTER_DATE)
)
COMMENT = 'Combined Ratio mart: quarterly loss, expense, and combined ratios by LOB';

-- =============================================================================
-- MART_CLAIMS_SETTLEMENT — Claims processing cycle time
-- Grain: 1 row per claim
-- Schema: PAYER360_CUR.CLAIMS
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.CLAIMS.MART_CLAIMS_SETTLEMENT (
    CLAIM_ID                  STRING(20)    NOT NULL,
    MEMBER_ID                 STRING(20)    NOT NULL,
    MEMBER_NAME               STRING(100),
    PROVIDER_NPI              STRING(10),
    PROVIDER_NAME             STRING(100),
    SERVICE_DATE              DATE          NOT NULL,
    RECEIVED_DATE             DATE,
    ADJUDICATED_DATE          DATE,
    PAID_DATE                 DATE,
    DAYS_TO_ADJUDICATE        INTEGER,
    DAYS_TO_PAY               INTEGER,
    TOTAL_CYCLE_DAYS          INTEGER,
    IS_CLEAN_CLAIM            BOOLEAN,
    IS_AUTO_ADJUDICATED       BOOLEAN,
    CLAIM_STATUS              STRING(20),
    CHARGE_AMT                FLOAT,
    PAID_AMT                  FLOAT,
    LINE_OF_BUSINESS          STRING(30),
    PLAN_TYPE                 STRING(10),
    PRIMARY KEY (CLAIM_ID)
)
COMMENT = 'Claims Settlement mart: processing cycle times with clean claim and auto-adjudication flags';

-- =============================================================================
-- MART_PROVIDER_NETWORK — Provider network health and turnover
-- Grain: 1 row per provider-contract
-- Schema: PAYER360_CUR.NETWORK
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.NETWORK.MART_PROVIDER_NETWORK (
    PROVIDER_NPI              STRING(10)    NOT NULL,
    PROVIDER_NAME             STRING(100),
    SPECIALTY                 STRING(50),
    PRACTICE_NAME             STRING(100),
    REGION_NAME               STRING(50),
    CONTRACT_START            DATE          NOT NULL,
    CONTRACT_END              DATE,
    IS_ACTIVE                 BOOLEAN,
    IS_TERMINATED             BOOLEAN,
    TERMINATION_REASON        STRING(50),
    CONTRACT_YEARS            FLOAT,
    CLAIMS_VOLUME             INTEGER,
    MEMBER_PANEL_SIZE         INTEGER,
    QUALITY_SCORE             FLOAT,
    TENURE_YEARS              FLOAT,
    PRIMARY KEY (PROVIDER_NPI, CONTRACT_START)
)
COMMENT = 'Provider Network mart: contract-level network health with quality and tenure metrics';
