-- =============================================================================
-- Payer360 Demo: Fact Table DDLs
-- =============================================================================
-- Run as: SYSADMIN (after dimensions exist)
-- Prerequisite: 03_dimensions.sql executed
-- =============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE P360_LOAD_WH;

-- =============================================================================
-- FCT_CLAIM — 1 row per claim line (PAYER360_CUR.CLAIMS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.CLAIMS.FCT_CLAIM (
    CLAIM_SK              INTEGER       NOT NULL AUTOINCREMENT,
    CLAIM_ID              STRING(20)    NOT NULL,
    LINE_NUMBER           INTEGER       NOT NULL,
    MEMBER_SK             INTEGER       NOT NULL,
    PROVIDER_SK           INTEGER       NOT NULL,
    DX_SK                 INTEGER,
    PROC_SK               INTEGER,
    PLAN_SK               INTEGER       NOT NULL,
    LOB_SK                INTEGER       NOT NULL,
    SERVICE_DATE          DATE          NOT NULL,
    SERVICE_DATE_KEY      INTEGER       NOT NULL,
    RECEIVED_DATE         DATE          NOT NULL,
    ADJUDICATED_DATE      DATE,
    PAID_DATE             DATE,
    CHARGE_AMT            FLOAT         NOT NULL,
    ALLOWED_AMT           FLOAT,
    PAID_AMT              FLOAT,
    MEMBER_RESPONSIBILITY FLOAT,
    IS_DENIED             BOOLEAN       NOT NULL DEFAULT FALSE,
    DENIAL_REASON         STRING(50),
    DENIAL_CATEGORY       STRING(30),   -- Clinical, Administrative, Coverage, Duplicate
    CLAIM_STATUS          STRING(20)    NOT NULL,  -- PAID, DENIED, PENDING, APPEALED
    IS_CLEAN_CLAIM        BOOLEAN       NOT NULL DEFAULT TRUE,
    IS_AUTO_ADJUDICATED   BOOLEAN       NOT NULL DEFAULT FALSE,
    IS_APPEALED           BOOLEAN       NOT NULL DEFAULT FALSE,
    APPEAL_OUTCOME        STRING(20),   -- UPHELD, OVERTURNED, PARTIAL, PENDING
    PLACE_OF_SERVICE      STRING(5),
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (CLAIM_SK)
)
COMMENT = 'Claims fact: ~800K claim lines with adjudication and denial detail';

-- =============================================================================
-- FCT_PREMIUM — 1 row per member-month (PAYER360_CUR.FINANCIAL)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.FINANCIAL.FCT_PREMIUM (
    PREMIUM_SK            INTEGER       NOT NULL AUTOINCREMENT,
    MEMBER_SK             INTEGER       NOT NULL,
    PLAN_SK               INTEGER       NOT NULL,
    LOB_SK                INTEGER       NOT NULL,
    PREMIUM_MONTH         DATE          NOT NULL,  -- first of month
    PREMIUM_DATE_KEY      INTEGER       NOT NULL,
    PREMIUM_EARNED        FLOAT         NOT NULL,
    INCURRED_CLAIMS_AMT   FLOAT,
    QUALITY_IMPROVEMENT_AMT FLOAT,
    ADMIN_EXPENSE_AMT     FLOAT,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (PREMIUM_SK)
)
COMMENT = 'Premium fact: ~600K member-month premium and incurred cost records';

-- =============================================================================
-- FCT_ENROLLMENT — 1 row per enrollment event (PAYER360_CUR.MEMBERSHIP)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.MEMBERSHIP.FCT_ENROLLMENT (
    ENROLLMENT_SK         INTEGER       NOT NULL AUTOINCREMENT,
    MEMBER_SK             INTEGER       NOT NULL,
    PLAN_SK               INTEGER       NOT NULL,
    LOB_SK                INTEGER       NOT NULL,
    EVENT_TYPE            STRING(20)    NOT NULL,  -- ENROLL, RENEW, TERM, TRANSFER
    EVENT_DATE            DATE          NOT NULL,
    EVENT_DATE_KEY        INTEGER       NOT NULL,
    EFFECTIVE_DATE        DATE          NOT NULL,
    TERM_DATE             DATE,
    TERM_REASON           STRING(50),
    PRIOR_PLAN_SK         INTEGER,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ENROLLMENT_SK)
)
COMMENT = 'Enrollment fact: ~100K enrollment lifecycle events';

-- =============================================================================
-- FCT_SURVEY — 1 row per survey response (PAYER360_CUR.MEMBER_EXPERIENCE)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.MEMBER_EXPERIENCE.FCT_SURVEY (
    SURVEY_SK             INTEGER       NOT NULL AUTOINCREMENT,
    SURVEY_ID             STRING(20)    NOT NULL,
    MEMBER_SK             INTEGER       NOT NULL,
    PLAN_SK               INTEGER       NOT NULL,
    LOB_SK                INTEGER       NOT NULL,
    SURVEY_DATE           DATE          NOT NULL,
    SURVEY_DATE_KEY       INTEGER       NOT NULL,
    NPS_SCORE             INTEGER       NOT NULL,  -- 0-10
    SATISFACTION_SCORE    INTEGER       NOT NULL,  -- 1-10
    TOPIC                 STRING(50),
    CHANNEL               STRING(20),   -- Email, Phone, Web, App
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (SURVEY_SK),
    UNIQUE (SURVEY_ID)
)
COMMENT = 'Survey fact: ~50K member satisfaction and NPS responses';

-- =============================================================================
-- FCT_PROVIDER_CONTRACT — 1 row per contract (PAYER360_CUR.NETWORK)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.NETWORK.FCT_PROVIDER_CONTRACT (
    CONTRACT_SK           INTEGER       NOT NULL AUTOINCREMENT,
    PROVIDER_SK           INTEGER       NOT NULL,
    REGION_SK             INTEGER       NOT NULL,
    CONTRACT_START        DATE          NOT NULL,
    CONTRACT_END          DATE,
    IS_ACTIVE             BOOLEAN       NOT NULL DEFAULT TRUE,
    IS_TERMINATED         BOOLEAN       NOT NULL DEFAULT FALSE,
    TERMINATION_REASON    STRING(50),
    FEE_SCHEDULE_TYPE     STRING(30)    NOT NULL,  -- STANDARD, CAPITATED, VALUE_BASED, BUNDLED
    QUALITY_SCORE         FLOAT,        -- 0-100
    CLAIMS_VOLUME         INTEGER,
    MEMBER_PANEL_SIZE     INTEGER,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (CONTRACT_SK)
)
COMMENT = 'Provider contract fact: ~5K network contracts';

-- =============================================================================
-- FCT_GRIEVANCE — 1 row per grievance (PAYER360_CUR.MEMBER_EXPERIENCE)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.MEMBER_EXPERIENCE.FCT_GRIEVANCE (
    GRIEVANCE_SK          INTEGER       NOT NULL AUTOINCREMENT,
    GRIEVANCE_ID          STRING(20)    NOT NULL,
    MEMBER_SK             INTEGER       NOT NULL,
    PLAN_SK               INTEGER       NOT NULL,
    LOB_SK                INTEGER       NOT NULL,
    FILED_DATE            DATE          NOT NULL,
    FILED_DATE_KEY        INTEGER       NOT NULL,
    CATEGORY              STRING(50)    NOT NULL,  -- Billing, Access, Quality, Communication
    RESOLUTION_DATE       DATE,
    RESOLUTION_DAYS       INTEGER,
    STATUS                STRING(20)    NOT NULL,  -- OPEN, RESOLVED, ESCALATED
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (GRIEVANCE_SK),
    UNIQUE (GRIEVANCE_ID)
)
COMMENT = 'Grievance fact: ~15K member complaints and resolutions';

-- =============================================================================
-- FCT_AUTHORIZATION — 1 row per prior auth request (PAYER360_CUR.CLAIMS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS PAYER360_CUR.CLAIMS.FCT_AUTHORIZATION (
    AUTH_SK               INTEGER       NOT NULL AUTOINCREMENT,
    AUTH_ID               STRING(20)    NOT NULL,
    MEMBER_SK             INTEGER       NOT NULL,
    PROVIDER_SK           INTEGER       NOT NULL,
    PROC_SK               INTEGER,
    PLAN_SK               INTEGER       NOT NULL,
    LOB_SK                INTEGER       NOT NULL,
    REQUEST_DATE          DATE          NOT NULL,
    REQUEST_DATE_KEY      INTEGER       NOT NULL,
    DECISION_DATE         DATE,
    DECISION              STRING(20)    NOT NULL,  -- APPROVED, DENIED, PARTIAL
    DENIAL_REASON         STRING(50),
    DAYS_TO_DECIDE        INTEGER,
    IS_EXPEDITED          BOOLEAN       NOT NULL DEFAULT FALSE,
    _LOADED_AT            TIMESTAMP     DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (AUTH_SK),
    UNIQUE (AUTH_ID)
)
COMMENT = 'Prior authorization fact: ~200K auth requests with decisions';
