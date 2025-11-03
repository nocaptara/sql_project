-- synthetic_data.sql
-- Generate larger synthetic data (10k+ rows) for demo/perf tests (PostgreSQL)

-- Products: add 20 synthetic
INSERT INTO dwh.products (product_sku, product_name, category, launch_date, is_active)
SELECT
    'SKU-' || 3000 + g::int,
    'Prod ' || g::int,
    (ARRAY['Software','Hardware','Service'])[(1 + (random()*2)::int)],
    ('2023-01-01'::date + ((random()*365)::int)),
    TRUE
FROM generate_series(1,20) g
ON CONFLICT (product_sku) DO NOTHING;

-- Employees: add 200 synthetic
INSERT INTO dwh.employees (employee_code, full_name, department, role_title, join_date, salary_usd)
SELECT
    'EMP-' || 1000 + g::int,
    'Employee ' || g::int,
    (ARRAY['Sales','Marketing','Support','Ops','Finance'])[(1 + (random()*4)::int)],
    (ARRAY['AE','AM','Analyst','SE','Mgr'])[(1 + (random()*4)::int)],
    ('2022-01-01'::date + ((random()*800)::int)),
    round(40000 + random()*40000, 2)
FROM generate_series(1,200) g
ON CONFLICT (employee_code) DO NOTHING;

-- Sales: ~10k rows across 2024
WITH dates AS (
  SELECT generate_series('2024-01-01'::date, '2024-12-31'::date, interval '1 day')::date AS d
),
pick_prod AS (
  SELECT product_id FROM dwh.products
),
pick_emp AS (
  SELECT employee_id FROM dwh.employees
)
INSERT INTO dwh.sales (sale_date, product_id, employee_id, region, quantity, unit_price_usd, discount_pct, revenue_usd)
SELECT
  d,
  (SELECT product_id FROM dwh.products ORDER BY random() LIMIT 1),
  (SELECT employee_id FROM dwh.employees ORDER BY random() LIMIT 1),
  (ARRAY['India','APAC','EMEA','Americas'])[(1 + (random()*3)::int)],
  (1 + (random()*10)::int),
  round(50 + random()*500, 2),
  round(random()*20, 2),
  NULL
FROM dates, generate_series(1,30); -- 365*30 ~ 10,950 rows

-- Recalculate revenue after insert
UPDATE dwh.sales
SET revenue_usd = round(quantity * unit_price_usd * (1 - discount_pct/100.0), 2)
WHERE revenue_usd IS NULL;

-- Financials product-level monthly
WITH months AS (
  SELECT generate_series('2024-01-01'::date, '2024-12-01'::date, interval '1 month')::date AS m
)
INSERT INTO dwh.financials (fin_month, level, product_id, revenue_usd, cogs_usd, opex_usd, current_assets, current_liab, equity_usd, debt_usd)
SELECT
  m.m, 'product', p.product_id,
  round(10000 + random()*90000,2),
  round(4000 + random()*40000,2),
  round(3000 + random()*30000,2),
  NULL, NULL, NULL, NULL
FROM months m
CROSS JOIN LATERAL (SELECT product_id FROM dwh.products ORDER BY random() LIMIT 1) p;
