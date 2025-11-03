-- pipeline/audit_log.sql
-- Minimal audit framework for pipeline runs

CREATE TABLE IF NOT EXISTS dwh.audit_log (
    run_id        BIGSERIAL PRIMARY KEY,
    pipeline_name TEXT NOT NULL,
    step_name     TEXT NOT NULL,
    status        TEXT NOT NULL CHECK (status IN ('started','success','failed')),
    row_count     BIGINT,
    started_at    TIMESTAMPTZ DEFAULT now(),
    ended_at      TIMESTAMPTZ
);

-- Utility function to record a step
CREATE OR REPLACE FUNCTION dwh.audit_mark(
    p_pipeline TEXT, p_step TEXT, p_status TEXT, p_rows BIGINT
) RETURNS VOID AS $$
BEGIN
  INSERT INTO dwh.audit_log (pipeline_name, step_name, status, row_count, ended_at)
  VALUES (p_pipeline, p_step, p_status, p_rows, now());
END;
$$ LANGUAGE plpgsql;

-- Example usage pattern:
-- SELECT dwh.audit_mark('daily_load','staging_to_clean','success', 1234);
