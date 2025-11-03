-- sample_data.sql
-- Seed minimal reference data for a quick demo

INSERT INTO dwh.products (product_sku, product_name, category, launch_date) VALUES
('SKU-1001','Alpha Analytics','Software','2023-01-10'),
('SKU-1002','Beta Insights','Software','2023-06-15'),
('SKU-2001','Gamma Gadget','Hardware','2024-02-01')
ON CONFLICT (product_sku) DO NOTHING;

INSERT INTO dwh.employees (employee_code, full_name, department, role_title, join_date, salary_usd) VALUES
('EMP-001','Asha Verma','Sales','AE','2023-02-01', 45000),
('EMP-002','Rohan Shah','Sales','AE','2023-04-10', 47000),
('EMP-003','Meera Iyer','Marketing','Analyst','2023-07-20', 52000)
ON CONFLICT (employee_code) DO NOTHING;

-- A few sales
INSERT INTO dwh.sales (sale_date, product_id, employee_id, region, quantity, unit_price_usd, discount_pct, revenue_usd)
SELECT d::date, p.product_id, e.employee_id, 'India', (5 + (random()*10)::int), 199.99, 5,
       ((5 + (random()*10)::int) * 199.99) * (1 - 0.05)
FROM generate_series('2024-01-01','2024-01-15', interval '1 day') d
CROSS JOIN LATERAL (SELECT product_id FROM dwh.products ORDER BY product_id LIMIT 1) p
CROSS JOIN LATERAL (SELECT employee_id FROM dwh.employees ORDER BY employee_id LIMIT 1) e;

-- Financials monthly (company level)
INSERT INTO dwh.financials (fin_month, level, revenue_usd, cogs_usd, opex_usd, current_assets, current_liab, equity_usd, debt_usd)
VALUES
('2024-01-01','company', 150000, 60000, 40000, 120000, 80000, 500000, 200000),
('2024-02-01','company', 165000, 65000, 42000, 125000, 82000, 505000, 200000)
ON CONFLICT DO NOTHING;

-- Compliance examples
INSERT INTO dwh.compliance (comp_date, area, severity, status, owner_dept, notes) VALUES
('2024-01-12','Data Privacy','high','open','Security','PII exposure in test logs'),
('2024-02-05','Tax','medium','mitigated','Finance','Late filing resolved');
