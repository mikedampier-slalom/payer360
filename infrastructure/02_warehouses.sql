-- =============================================================================
-- Payer360 Demo: Warehouse Setup
-- =============================================================================
-- Run as: SYSADMIN
-- =============================================================================

USE ROLE SYSADMIN;

-- -----------------------------------------------------------------------------
-- P360_LOAD_WH — Ingest workloads (Snowpipe, COPY INTO, etc.)
-- -----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS P360_LOAD_WH
  WAREHOUSE_SIZE   = 'MEDIUM'
  AUTO_SUSPEND     = 300
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Payer360: Ingest / data loading warehouse';

-- -----------------------------------------------------------------------------
-- P360_XFM_WH — Transform workloads (dbt, Tasks, Dynamic Tables)
-- -----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS P360_XFM_WH
  WAREHOUSE_SIZE   = 'SMALL'
  AUTO_SUSPEND     = 300
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Payer360: Transformation warehouse (dbt, tasks, dynamic tables)';

-- -----------------------------------------------------------------------------
-- P360_BI_WH — BI / Demo queries
-- -----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS P360_BI_WH
  WAREHOUSE_SIZE   = 'XSMALL'
  AUTO_SUSPEND     = 300
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Payer360: BI / demo query warehouse';

-- -----------------------------------------------------------------------------
-- P360_ML_WH — Cortex ML / AI workloads
-- -----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS P360_ML_WH
  WAREHOUSE_SIZE   = 'SMALL'
  AUTO_SUSPEND     = 300
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Payer360: ML / Cortex AI warehouse';
