-- analytics_queries.sql
-- KPIs and analysis snippets

-- 1) Financial KPIs (company-level)
-- Current Ratio = Current Assets / Current Liabilities
SELECT fin_month,
       NULLIF(current_assets,0) / NULLIF(current_liab,0) AS current_ratio
FROM dwh.financials
WHERE level = 'company'
ORDER BY fin_month;

-- ROE = Net Income / Equity (approx: (revenue - cogs - opex)/equity)
SELECT fin_month,
       NULLIF((revenue_usd - cogs_usd - opex_usd),0) / NULLIF(equity_usd,0) AS roe
FROM dwh.financials
WHERE level = 'company'
ORDER BY fin_month;

-- 2) Workforce KPIs
-- Attrition: headcount movement by month using window functions
WITH emp_months AS (
  SELECT e.employee_id, e.department,
         generate_series(date_trunc('month', COALESCE(e.join_date, now()))::date,
                         date_trunc('month', COALESCE(COALESCE(e.exit_date, now()), now()))::date,
                         interval '1 month')::date AS m
  FROM dwh.employees e
)
SELECT m,
       department,
       COUNT(DISTINCT employee_id) AS headcount
FROM emp_months
GROUP BY 1,2
ORDER BY 1,2;

-- 3) Sales trends: 7-day moving average by product
SELECT sale_date, product_id,
       AVG(revenue_usd) OVER (PARTITION BY product_id ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma7_revenue
FROM dwh.sales
ORDER BY product_id, sale_date;

-- 4) ROLLUP: revenue by region→product→month
SELECT
  date_trunc('month', sale_date)::date AS month,
  region,
  product_id,
  SUM(revenue_usd) AS total_revenue
FROM dwh.sales
GROUP BY ROLLUP (date_trunc('month', sale_date)::date, region, product_id)
ORDER BY 1,2,3;

-- 5) Recursive CTE: build a simple month calendar
WITH RECURSIVE months(m) AS (
  SELECT date_trunc('month', MIN(sale_date))::date FROM dwh.sales
  UNION ALL
  SELECT (m + interval '1 month')::date FROM months WHERE m < date_trunc('month', now())::date
)
SELECT * FROM months;
