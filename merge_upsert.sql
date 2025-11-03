-- pipeline/merge_upsert.sql
-- Incremental UPSERTS from cln.* into dwh.* (idempotent)

-- PRODUCTS
INSERT INTO dwh.products (product_sku, product_name, category, launch_date, is_active, created_at)
SELECT product_sku, product_name, category, launch_date, is_active, now()
FROM cln.products cp
ON CONFLICT (product_sku)
DO UPDATE SET
    product_name = EXCLUDED.product_name,
    category     = EXCLUDED.category,
    launch_date  = EXCLUDED.launch_date,
    is_active    = EXCLUDED.is_active;

-- EMPLOYEES
INSERT INTO dwh.employees (employee_code, full_name, department, role_title, join_date, exit_date, salary_usd, created_at)
SELECT employee_code, full_name, department, role_title, join_date, exit_date, salary_usd, now()
FROM cln.employees ce
ON CONFLICT (employee_code)
DO UPDATE SET
    full_name  = EXCLUDED.full_name,
    department = EXCLUDED.department,
    role_title = EXCLUDED.role_title,
    join_date  = EXCLUDED.join_date,
    exit_date  = EXCLUDED.exit_date,
    salary_usd = EXCLUDED.salary_usd;

-- SALES
INSERT INTO dwh.sales (sale_date, product_id, employee_id, region, quantity, unit_price_usd, discount_pct, revenue_usd, created_at)
SELECT
    sale_date, product_id, employee_id, region, quantity, unit_price_usd, discount_pct,
    round(quantity * unit_price_usd * (1 - discount_pct/100.0), 2),
    now()
FROM cln.sales cs
ON CONFLICT DO NOTHING; -- if you have a natural key, add a unique constraint and upsert

-- FINANCIALS
INSERT INTO dwh.financials (fin_month, level, product_id, revenue_usd, cogs_usd, opex_usd, current_assets, current_liab, equity_usd, debt_usd, created_at)
SELECT fin_month, level, product_id, revenue_usd, cogs_usd, opex_usd, current_assets, current_liab, equity_usd, debt_usd, now()
FROM cln.financials cf
ON CONFLICT (fin_month, level, product_id)
DO UPDATE SET
    revenue_usd = EXCLUDED.revenue_usd,
    cogs_usd    = EXCLUDED.cogs_usd,
    opex_usd    = EXCLUDED.opex_usd,
    current_assets = EXCLUDED.current_assets,
    current_liab   = EXCLUDED.current_liab,
    equity_usd     = EXCLUDED.equity_usd,
    debt_usd       = EXCLUDED.debt_usd;

-- COMPLIANCE
INSERT INTO dwh.compliance (comp_date, area, severity, status, owner_dept, notes, created_at)
SELECT comp_date, area, severity, status, owner_dept, notes, now()
FROM cln.compliance cc
ON CONFLICT DO NOTHING; -- add a unique constraint (comp_date, area) if you want upsert semantics
