-- pipeline/transformations.sql
-- Cleanse/standardize from raw.* into cln.* and then load to dwh.*

-- Clean tables
CREATE TABLE IF NOT EXISTS cln.products AS
SELECT * FROM dwh.products WHERE 1=0;

CREATE TABLE IF NOT EXISTS cln.employees AS
SELECT * FROM dwh.employees WHERE 1=0;

CREATE TABLE IF NOT EXISTS cln.sales AS
SELECT * FROM dwh.sales WHERE 1=0;

CREATE TABLE IF NOT EXISTS cln.financials AS
SELECT * FROM dwh.financials WHERE 1=0;

CREATE TABLE IF NOT EXISTS cln.compliance AS
SELECT * FROM dwh.compliance WHERE 1=0;

-- Simple cleansing examples from stg → cln (idempotent loads)
-- Products: trim names, fix category casing
INSERT INTO cln.products (product_id, product_sku, product_name, category, launch_date, is_active, created_at)
SELECT
    p.product_id, rp.product_sku,
    INITCAP(TRIM(rp.product_name)),
    INITCAP(TRIM(rp.category)),
    rp.launch_date,
    COALESCE(rp.is_active, TRUE),
    now()
FROM raw.stg_products rp
LEFT JOIN dwh.products p ON p.product_sku = rp.product_sku
ON CONFLICT DO NOTHING;

-- Employees: basic standardization
INSERT INTO cln.employees (employee_id, employee_code, full_name, department, role_title, join_date, exit_date, salary_usd, created_at)
SELECT
    e.employee_id, re.employee_code,
    INITCAP(TRIM(re.full_name)),
    INITCAP(TRIM(re.department)),
    INITCAP(TRIM(re.role_title)),
    re.join_date, re.exit_date, re.salary_usd,
    now()
FROM raw.stg_employees re
LEFT JOIN dwh.employees e ON e.employee_code = re.employee_code
ON CONFLICT DO NOTHING;

-- Sales: validate quantities/prices and join FKs
INSERT INTO cln.sales (sale_id, sale_date, product_id, employee_id, region, quantity, unit_price_usd, discount_pct, revenue_usd, created_at)
SELECT
    s.sale_id, rs.sale_date,
    p.product_id,
    e.employee_id,
    INITCAP(TRIM(rs.region)),
    GREATEST(0, rs.quantity),
    GREATEST(0, rs.unit_price_usd),
    LEAST(GREATEST(0, rs.discount_pct), 100),
    NULL,
    now()
FROM raw.stg_sales rs
LEFT JOIN dwh.products p  ON p.product_sku    = rs.product_sku
LEFT JOIN dwh.employees e ON e.employee_code  = rs.employee_code
LEFT JOIN dwh.sales s     ON s.sale_date = rs.sale_date
                          AND s.product_id = p.product_id
                          AND s.employee_id = e.employee_id
                          AND s.region = INITCAP(TRIM(rs.region))
                          AND s.quantity = GREATEST(0, rs.quantity)
                          AND s.unit_price_usd = GREATEST(0, rs.unit_price_usd)
                          AND s.discount_pct = LEAST(GREATEST(0, rs.discount_pct), 100)
ON CONFLICT DO NOTHING;

-- Financials: ensure month start, valid level
INSERT INTO cln.financials (fin_id, fin_month, level, product_id, revenue_usd, cogs_usd, opex_usd, current_assets, current_liab, equity_usd, debt_usd, created_at)
SELECT
    f.fin_id,
    date_trunc('month', rf.fin_month)::date,
    CASE WHEN LOWER(rf.level) IN ('company','product') THEN LOWER(rf.level) ELSE 'company' END,
    p.product_id,
    rf.revenue_usd, rf.cogs_usd, rf.opex_usd, rf.current_assets, rf.current_liab, rf.equity_usd, rf.debt_usd,
    now()
FROM raw.stg_financials rf
LEFT JOIN dwh.products p ON p.product_sku = rf.product_sku
LEFT JOIN dwh.financials f ON f.fin_month = date_trunc('month', rf.fin_month)::date
                           AND COALESCE(f.product_id,-1) = COALESCE(p.product_id,-1)
                           AND f.level = CASE WHEN LOWER(rf.level) IN ('company','product') THEN LOWER(rf.level) ELSE 'company' END
ON CONFLICT DO NOTHING;

-- Compliance: standardize enums
INSERT INTO cln.compliance (comp_id, comp_date, area, severity, status, owner_dept, notes, created_at)
SELECT
    c.comp_id,
    rc.comp_date,
    INITCAP(TRIM(rc.area)),
    CASE
        WHEN LOWER(rc.severity) IN ('low','medium','high','critical') THEN LOWER(rc.severity)
        ELSE 'low' END,
    CASE
        WHEN LOWER(rc.status) IN ('open','mitigated','ongoing','closed') THEN LOWER(rc.status)
        ELSE 'open' END,
    INITCAP(TRIM(rc.owner_dept)),
    rc.notes,
    now()
FROM raw.stg_compliance rc
LEFT JOIN dwh.compliance c ON c.comp_date = rc.comp_date AND c.area = INITCAP(TRIM(rc.area))
ON CONFLICT DO NOTHING;
