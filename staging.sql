-- pipeline/staging.sql
-- Raw staging tables (land data as-is)

CREATE TABLE IF NOT EXISTS raw.stg_products (
    product_sku    TEXT PRIMARY KEY,
    product_name   TEXT,
    category       TEXT,
    launch_date    DATE,
    is_active      BOOLEAN
);

CREATE TABLE IF NOT EXISTS raw.stg_employees (
    employee_code  TEXT PRIMARY KEY,
    full_name      TEXT,
    department     TEXT,
    role_title     TEXT,
    join_date      DATE,
    exit_date      DATE,
    salary_usd     NUMERIC(12,2)
);

CREATE TABLE IF NOT EXISTS raw.stg_sales (
    natural_key    TEXT PRIMARY KEY,  -- e.g., external order_line_id
    sale_date      DATE,
    product_sku    TEXT,
    employee_code  TEXT,
    region         TEXT,
    quantity       INTEGER,
    unit_price_usd NUMERIC(12,2),
    discount_pct   NUMERIC(5,2)
);

CREATE TABLE IF NOT EXISTS raw.stg_financials (
    natural_key    TEXT PRIMARY KEY,  -- e.g., fin_month + product_sku or "company-YYYY-MM"
    fin_month      DATE,
    level          TEXT,
    product_sku    TEXT,
    revenue_usd    NUMERIC(14,2),
    cogs_usd       NUMERIC(14,2),
    opex_usd       NUMERIC(14,2),
    current_assets NUMERIC(14,2),
    current_liab   NUMERIC(14,2),
    equity_usd     NUMERIC(14,2),
    debt_usd       NUMERIC(14,2)
);

CREATE TABLE IF NOT EXISTS raw.stg_compliance (
    natural_key    TEXT PRIMARY KEY, -- e.g., area+date
    comp_date      DATE,
    area           TEXT,
    severity       TEXT,
    status         TEXT,
    owner_dept     TEXT,
    notes          TEXT
);
