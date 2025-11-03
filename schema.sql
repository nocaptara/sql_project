-- schema.sql
-- Create schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS cln;
CREATE SCHEMA IF NOT EXISTS dwh;

-- ============ CORE TABLES (Analytics layer targets) ============

-- Products dimension (slow-moving)
CREATE TABLE IF NOT EXISTS dwh.products (
    product_id       BIGSERIAL PRIMARY KEY,
    product_sku      TEXT UNIQUE,
    product_name     TEXT NOT NULL,
    category         TEXT,
    launch_date      DATE,
    is_active        BOOLEAN DEFAULT TRUE,
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- Employees dimension
CREATE TABLE IF NOT EXISTS dwh.employees (
    employee_id      BIGSERIAL PRIMARY KEY,
    employee_code    TEXT UNIQUE,
    full_name        TEXT NOT NULL,
    department       TEXT,
    role_title       TEXT,
    join_date        DATE,
    exit_date        DATE,
    salary_usd       NUMERIC(12,2),
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- Sales fact
CREATE TABLE IF NOT EXISTS dwh.sales (
    sale_id          BIGSERIAL PRIMARY KEY,
    sale_date        DATE NOT NULL,
    product_id       BIGINT REFERENCES dwh.products(product_id),
    employee_id      BIGINT REFERENCES dwh.employees(employee_id),
    region           TEXT,
    quantity         INTEGER CHECK (quantity >= 0),
    unit_price_usd   NUMERIC(12,2) CHECK (unit_price_usd >= 0),
    discount_pct     NUMERIC(5,2)  CHECK (discount_pct BETWEEN 0 AND 100),
    revenue_usd      NUMERIC(14,2),
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- Financials fact (monthly at company or product level)
CREATE TABLE IF NOT EXISTS dwh.financials (
    fin_id           BIGSERIAL PRIMARY KEY,
    fin_month        DATE NOT NULL, -- first day of month
    level            TEXT NOT NULL CHECK (level IN ('company','product')),
    product_id       BIGINT REFERENCES dwh.products(product_id),
    revenue_usd      NUMERIC(14,2),
    cogs_usd         NUMERIC(14,2),
    opex_usd         NUMERIC(14,2),
    current_assets   NUMERIC(14,2),
    current_liab     NUMERIC(14,2),
    equity_usd       NUMERIC(14,2),
    debt_usd         NUMERIC(14,2),
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- Compliance/risk fact
CREATE TABLE IF NOT EXISTS dwh.compliance (
    comp_id          BIGSERIAL PRIMARY KEY,
    comp_date        DATE NOT NULL,
    area             TEXT NOT NULL,      -- e.g., "Data Privacy", "Tax"
    severity         TEXT NOT NULL CHECK (severity IN ('low','medium','high','critical')),
    status           TEXT NOT NULL CHECK (status IN ('open','mitigated','ongoing','closed')),
    owner_dept       TEXT,
    notes            TEXT,
    created_at       TIMESTAMPTZ DEFAULT now()
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_sales_date ON dwh.sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_financials_month ON dwh.financials(fin_month);
CREATE INDEX IF NOT EXISTS idx_compliance_date ON dwh.compliance(comp_date);
