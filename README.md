# Investment Analytics Data Warehouse (PostgreSQL)

**Last generated:** 2025-11-03 15:20:45

This project simulates a real-world investment decision-making system using SQL-first data engineering patterns:
- Ingestion (staging) → Cleansing → Analytics
- Incremental upserts (MERGE/UPSERT)
- Audit logging for pipeline observability
- Analytics: KPIs with window functions, ROLLUP/GROUPING SETS, recursive CTE
- Views + parameterized reporting function

> Default dialect: **PostgreSQL 13+**.  
> For SQL Server, see inline comments marked `-- SQL Server note:` and adjust `SERIAL/IDENTITY`, `ON CONFLICT`, `GENERATE_SERIES`, and date functions accordingly.

## Run Order
1. `schema.sql`
2. `sample_data.sql` (or `synthetic_data.sql` to generate larger test data)
3. `pipeline/staging.sql`
4. `pipeline/transformations.sql`
5. `pipeline/merge_upsert.sql`
6. `pipeline/audit_log.sql`
7. `procedures_views.sql`
8. (Optional) Explore `analytics_queries.sql`

## Schemas (logical)
- `raw` (staging)
- `cln` (cleansed)
- `dwh` (analytics)

---
