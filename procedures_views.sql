-- procedures_views.sql

-- Summary view for dashboards
CREATE OR REPLACE VIEW dwh.vw_investment_summary AS
SELECT
  s.sale_date,
  p.product_id,
  p.product_name,
  e.department,
  e.role_title,
  s.region,
  s.quantity,
  s.unit_price_usd,
  s.discount_pct,
  s.revenue_usd
FROM dwh.sales s
LEFT JOIN dwh.products p  ON p.product_id = s.product_id
LEFT JOIN dwh.employees e ON e.employee_id = s.employee_id;

-- Parameterized reporting function (returns a set of rows)
-- Example: SELECT * FROM dwh.sp_generate_investment_report('2024-01-01','2024-12-31', 'Software');
CREATE OR REPLACE FUNCTION dwh.sp_generate_investment_report(p_from DATE, p_to DATE, p_category TEXT DEFAULT NULL)
RETURNS TABLE (
  sale_date DATE,
  product_name TEXT,
  category TEXT,
  region TEXT,
  revenue_usd NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT s.sale_date, p.product_name, p.category, s.region, s.revenue_usd
  FROM dwh.sales s
  JOIN dwh.products p ON p.product_id = s.product_id
  WHERE s.sale_date BETWEEN p_from AND p_to
    AND (p_category IS NULL OR p.category = p_category)
  ORDER BY s.sale_date, p.product_name;
END;
$$ LANGUAGE plpgsql;

-- Helpful indexes for the view/report
CREATE INDEX IF NOT EXISTS idx_sales_region ON dwh.sales(region);
CREATE INDEX IF NOT EXISTS idx_products_category ON dwh.products(category);
