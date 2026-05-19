-- =============================================================================
-- Payer360 Demo: Dimension Table DDLs
-- =============================================================================
-- Run as: SYSADMIN (after databases/schemas exist)
-- Prerequisite: 01_databases.sql executed
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE P360_LOAD_WH;

-- =============================================================================
-- DIM_DATE — Universal date spine (PAYER360_CUR.COMMON)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.COMMON.DIM_DATE (
    DATE_KEY          INTEGER       NOT NULL,  -- YYYYMMDD
    FULL_DATE         DATE          NOT NULL,
    YEAR              INTEGER       NOT NULL,
    QUARTER           INTEGER       NOT NULL,
    MONTH             INTEGER       NOT NULL,
    MONTH_NAME        STRING(10)    NOT NULL,
    DAY_OF_MONTH      INTEGER       NOT NULL,
    DAY_OF_WEEK       INTEGER       NOT NULL,  -- 0=Sun, 6=Sat
    DAY_NAME          STRING(10)    NOT NULL,
    WEEK_OF_YEAR      INTEGER       NOT NULL,
    FISCAL_YEAR       INTEGER       NOT NULL,  -- January fiscal year start
    FISCAL_QUARTER    INTEGER       NOT NULL,
    IS_WEEKEND        BOOLEAN       NOT NULL,
    IS_HOLIDAY        BOOLEAN       NOT NULL DEFAULT FALSE,
    HOLIDAY_NAME      STRING(50),
    PRIMARY KEY (DATE_KEY)
)
COMMENT = 'Conformed date dimension: 2023-01-01 to 2025-12-31';

-- =============================================================================
-- DIM_MEMBER — Member master (PAYER360_CUR.MEMBERSHIP)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.MEMBERSHIP.DIM_MEMBER (
    MEMBER_SK             INTEGER       NOT NULL AUTOINCREMENT,
    MEMBER_ID             STRING(20)    NOT NULL,
    FIRST_NAME            STRING(50)    NOT NULL,
    LAST_NAME             STRING(50)    NOT NULL,
    DOB                   DATE          NOT NULL,
    GENDER                STRING(10)    NOT NULL,
    RACE                  STRING(30),
    LANGUAGE              STRING(20)    DEFAULT 'English',
    PHONE                 STRING(15),
    EMAIL                 STRING(100),
    ADDRESS               STRING(200),
    CITY                  STRING(50),
    STATE                 STRING(2),
    ZIP                   STRING(10),
    COUNTY                STRING(50),
    PLAN_ID               STRING(20),
    LINE_OF_BUSINESS      STRING(30),
    ENROLLMENT_DATE       DATE,
    RISK_SCORE            FLOAT,
    CHRONIC_CONDITION_COUNT INTEGER,
    IS_ACTIVE             BOOLEAN       NOT NULL DEFAULT TRUE,
    DEATH_DATE            DATE,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (MEMBER_SK),
    UNIQUE (MEMBER_ID)
)
COMMENT = 'Conformed member dimension: 50K synthetic members with demographics';

-- =============================================================================
-- DIM_PROVIDER — Provider master (PAYER360_CUR.NETWORK)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.NETWORK.DIM_PROVIDER (
    PROVIDER_SK           INTEGER       NOT NULL AUTOINCREMENT,
    NPI                   STRING(10)    NOT NULL,
    FIRST_NAME            STRING(50)    NOT NULL,
    LAST_NAME             STRING(50)    NOT NULL,
    CREDENTIAL            STRING(20),   -- MD, DO, NP, PA
    SPECIALTY             STRING(50)    NOT NULL,
    SUBSPECIALTY          STRING(50),
    PRACTICE_NAME         STRING(100),
    PRACTICE_TYPE         STRING(50),
    ADDRESS               STRING(200),
    CITY                  STRING(50),
    STATE                 STRING(2),
    ZIP                   STRING(10),
    REGION_ID             STRING(10),
    CONTRACT_STATUS       STRING(20),
    CONTRACT_START        DATE,
    IS_ACTIVE             BOOLEAN       NOT NULL DEFAULT TRUE,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (PROVIDER_SK),
    UNIQUE (NPI)
)
COMMENT = 'Conformed provider dimension: 500 synthetic providers with specialties';

-- =============================================================================
-- DIM_PLAN — Plan catalog (PAYER360_CUR.MEMBERSHIP)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.MEMBERSHIP.DIM_PLAN (
    PLAN_SK               INTEGER       NOT NULL AUTOINCREMENT,
    PLAN_ID               STRING(20)    NOT NULL,
    PLAN_NAME             STRING(100)   NOT NULL,
    PLAN_TYPE             STRING(10)    NOT NULL,  -- HMO, PPO, EPO, HDHP, POS
    LINE_OF_BUSINESS      STRING(30)    NOT NULL,
    METAL_TIER            STRING(10),   -- Bronze, Silver, Gold, Platinum
    MONTHLY_PREMIUM       FLOAT,
    DEDUCTIBLE            FLOAT,
    MAX_OOP               FLOAT,
    COPAY_PCP             FLOAT,
    COPAY_SPECIALIST      FLOAT,
    IS_ACTIVE             BOOLEAN       NOT NULL DEFAULT TRUE,
    EFFECTIVE_DATE        DATE,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (PLAN_SK),
    UNIQUE (PLAN_ID)
)
COMMENT = 'Conformed plan dimension: plan catalog with benefit details';

-- =============================================================================
-- DIM_LINE_OF_BUSINESS — LOB reference (PAYER360_CUR.FINANCIAL)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.FINANCIAL.DIM_LINE_OF_BUSINESS (
    LOB_SK                INTEGER       NOT NULL AUTOINCREMENT,
    LOB_ID                STRING(10)    NOT NULL,
    LOB_NAME              STRING(50)    NOT NULL,
    DESCRIPTION           STRING(200),
    MLR_THRESHOLD         FLOAT         NOT NULL,  -- 0.80 or 0.85
    REGULATORY_BODY       STRING(50),
    IS_ACTIVE             BOOLEAN       NOT NULL DEFAULT TRUE,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (LOB_SK),
    UNIQUE (LOB_ID)
)
COMMENT = 'Conformed line-of-business dimension: Individual, Small/Large Group, Medicare Advantage, Medicaid';

-- =============================================================================
-- DIM_DIAGNOSIS_ICD10 — ICD-10 codes (PAYER360_CUR.CLAIMS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.CLAIMS.DIM_DIAGNOSIS_ICD10 (
    DX_SK                 INTEGER       NOT NULL AUTOINCREMENT,
    ICD10_CODE            STRING(10)    NOT NULL,
    DESCRIPTION           STRING(255)   NOT NULL,
    CHAPTER               STRING(5),
    CHAPTER_DESC          STRING(100),
    CATEGORY              STRING(10),
    IS_CHRONIC            BOOLEAN       NOT NULL DEFAULT FALSE,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (DX_SK),
    UNIQUE (ICD10_CODE)
)
COMMENT = 'ICD-10 diagnosis dimension: ~200 common codes';

-- =============================================================================
-- DIM_PROCEDURE_CPT — CPT codes (PAYER360_CUR.CLAIMS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.CLAIMS.DIM_PROCEDURE_CPT (
    PROC_SK               INTEGER       NOT NULL AUTOINCREMENT,
    CPT_CODE              STRING(10)    NOT NULL,
    DESCRIPTION           STRING(255)   NOT NULL,
    CATEGORY              STRING(50),   -- E&M, Surgery, Radiology, Lab, Medicine
    SUBCATEGORY           STRING(50),
    FEE_SCHEDULE_AMT      FLOAT,
    REQUIRES_AUTH         BOOLEAN       NOT NULL DEFAULT FALSE,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (PROC_SK),
    UNIQUE (CPT_CODE)
)
COMMENT = 'CPT procedure dimension: ~150 common codes with fee schedule amounts';

-- =============================================================================
-- DIM_REGION — Geographic regions (PAYER360_CUR.NETWORK)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.NETWORK.DIM_REGION (
    REGION_SK             INTEGER       NOT NULL AUTOINCREMENT,
    REGION_ID             STRING(10)    NOT NULL,
    REGION_NAME           STRING(50)    NOT NULL,
    STATE                 STRING(2)     NOT NULL,
    MARKET_TYPE           STRING(20),   -- Urban, Suburban, Rural
    POPULATION            INTEGER,
    MEMBER_DENSITY        FLOAT,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (REGION_SK),
    UNIQUE (REGION_ID)
)
COMMENT = 'Conformed region dimension: geographic service areas with market type';
