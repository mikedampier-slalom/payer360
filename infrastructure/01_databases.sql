-- =============================================================================
-- Payer360 Demo: Database & Schema Setup
-- =============================================================================
-- Run as: SYSADMIN
-- =============================================================================

USE ROLE SYSADMIN;

-- -----------------------------------------------------------------------------
-- 1. PAYER360_RAW — Bronze / Landing Zone
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS PAYER360_RAW
  COMMENT = 'Payer360 Demo: Bronze layer — raw ingested data from EDI, enrollment, premium, surveys';

CREATE SCHEMA IF NOT EXISTS PAYER360_RAW.CLAIMS_EDI
  COMMENT = 'Raw 835/837 EDI claim transactions';
CREATE SCHEMA IF NOT EXISTS PAYER360_RAW.ENROLLMENT
  COMMENT = 'Raw enrollment and eligibility feeds';
CREATE SCHEMA IF NOT EXISTS PAYER360_RAW.PREMIUM
  COMMENT = 'Raw premium billing and payment data';
CREATE SCHEMA IF NOT EXISTS PAYER360_RAW.SURVEYS
  COMMENT = 'Raw member satisfaction and NPS survey responses';
CREATE SCHEMA IF NOT EXISTS PAYER360_RAW.PROVIDER_CONTRACTS
  COMMENT = 'Raw provider network contract data';
CREATE SCHEMA IF NOT EXISTS PAYER360_RAW.MARKETPLACE
  COMMENT = 'Data from Snowflake Marketplace (NPPES, CMS, Census)';

-- -----------------------------------------------------------------------------
-- 2. PAYER360_INT — Silver / Integrated
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS PAYER360_INT
  COMMENT = 'Payer360 Demo: Silver layer — cleansed, conformed, PII-tagged';

CREATE SCHEMA IF NOT EXISTS PAYER360_INT.CLAIMS
  COMMENT = 'Integrated claims data (adjudication, denials, appeals)';
CREATE SCHEMA IF NOT EXISTS PAYER360_INT.MEMBERSHIP
  COMMENT = 'Integrated membership data (enrollment, eligibility, demographics)';
CREATE SCHEMA IF NOT EXISTS PAYER360_INT.FINANCIAL
  COMMENT = 'Integrated financial data (premium, loss ratios, reserves)';
CREATE SCHEMA IF NOT EXISTS PAYER360_INT.NETWORK
  COMMENT = 'Integrated provider network data (contracts, credentialing)';
CREATE SCHEMA IF NOT EXISTS PAYER360_INT.MEMBER_EXPERIENCE
  COMMENT = 'Integrated member experience data (surveys, grievances)';

-- -----------------------------------------------------------------------------
-- 3. PAYER360_CUR — Gold / Curated
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS PAYER360_CUR
  COMMENT = 'Payer360 Demo: Gold layer — analytics-ready dims, facts, and marts';

CREATE SCHEMA IF NOT EXISTS PAYER360_CUR.CLAIMS
  COMMENT = 'Claims dims/facts (DIM_DIAGNOSIS_ICD10, DIM_PROCEDURE_CPT, FCT_CLAIM, etc.)';
CREATE SCHEMA IF NOT EXISTS PAYER360_CUR.MEMBERSHIP
  COMMENT = 'Membership dims/facts (DIM_MEMBER, DIM_PLAN, FCT_ENROLLMENT, etc.)';
CREATE SCHEMA IF NOT EXISTS PAYER360_CUR.FINANCIAL
  COMMENT = 'Financial dims/facts (DIM_LINE_OF_BUSINESS, FCT_PREMIUM, etc.)';
CREATE SCHEMA IF NOT EXISTS PAYER360_CUR.NETWORK
  COMMENT = 'Network dims/facts (DIM_PROVIDER, DIM_REGION, FCT_PROVIDER_CONTRACT, etc.)';
CREATE SCHEMA IF NOT EXISTS PAYER360_CUR.MEMBER_EXPERIENCE
  COMMENT = 'Member experience dims/facts (FCT_SURVEY, FCT_GRIEVANCE, etc.)';
CREATE SCHEMA IF NOT EXISTS PAYER360_CUR.COMMON
  COMMENT = 'Shared conformed dimensions (DIM_DATE)';

-- -----------------------------------------------------------------------------
-- 4. PAYER360_ML — Feature Store + Model Registry
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS PAYER360_ML
  COMMENT = 'Payer360 Demo: ML layer — feature store, models, predictions, monitoring';

CREATE SCHEMA IF NOT EXISTS PAYER360_ML.FEATURES
  COMMENT = 'Feature tables for ML models';
CREATE SCHEMA IF NOT EXISTS PAYER360_ML.MODELS
  COMMENT = 'Cortex ML model registry and artifacts';
CREATE SCHEMA IF NOT EXISTS PAYER360_ML.PREDICTIONS
  COMMENT = 'Scored predictions / inference results';
CREATE SCHEMA IF NOT EXISTS PAYER360_ML.MONITORING
  COMMENT = 'Model drift and performance monitoring';

-- -----------------------------------------------------------------------------
-- 5. PAYER360_APP — Application Layer
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS PAYER360_APP
  COMMENT = 'Payer360 Demo: App layer — Streamlit, semantic views, Cortex Analyst, alerts';

CREATE SCHEMA IF NOT EXISTS PAYER360_APP.STREAMLIT
  COMMENT = 'Streamlit-in-Snowflake application objects';
CREATE SCHEMA IF NOT EXISTS PAYER360_APP.SEMANTIC_VIEWS
  COMMENT = 'Semantic view definitions for Cortex Analyst';
CREATE SCHEMA IF NOT EXISTS PAYER360_APP.CORTEX_ANALYST
  COMMENT = 'Cortex Analyst configuration and sample prompts';
CREATE SCHEMA IF NOT EXISTS PAYER360_APP.ALERTS
  COMMENT = 'Alert definitions and notification configuration';
