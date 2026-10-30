-- MIT 8103 Portfolio 2: baseline plans and warm-cache measurements.
-- Run after 03-build-benchmark-schema.sql. This script resets only the
-- benchmark's named indexes and measurement records inside p2_benchmark.

DROP INDEX IF EXISTS p2_benchmark.p2_accounts_customer_id_idx;
DROP INDEX IF EXISTS p2_benchmark.p2_accounts_type_balance_idx;
DROP INDEX IF EXISTS p2_benchmark.p2_transactions_source_history_idx;
DROP INDEX IF EXISTS p2_benchmark.p2_transactions_destination_history_idx;
DROP INDEX IF EXISTS p2_benchmark.p2_transactions_date_report_idx;

CREATE TABLE IF NOT EXISTS p2_benchmark.measurements (
    stage TEXT NOT NULL CHECK (stage IN ('baseline', 'indexed')),
    scenario TEXT NOT NULL,
    run_number INTEGER NOT NULL,
    elapsed_ms NUMERIC(12, 3) NOT NULL,
    shared_hit_blocks BIGINT NOT NULL,
    shared_read_blocks BIGINT NOT NULL,
    plan_json JSONB NOT NULL,
    PRIMARY KEY (stage, scenario, run_number)
);

CREATE TABLE IF NOT EXISTS p2_benchmark.result_signatures (
    stage TEXT NOT NULL CHECK (stage IN ('baseline', 'indexed')),
    scenario TEXT NOT NULL,
    result_count BIGINT NOT NULL,
    result_md5 TEXT NOT NULL,
    PRIMARY KEY (stage, scenario)
);

CREATE OR REPLACE FUNCTION p2_benchmark.capture_result_signature(
    p_stage TEXT,
    p_scenario TEXT,
    p_query_sql TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_count BIGINT;
    v_md5 TEXT;
    v_command TEXT;
BEGIN
    -- Sort serialized rows before hashing so result order does not affect parity.
    v_command :=
        'SELECT COUNT(*), MD5(COALESCE(STRING_AGG(row_data, E''\n'' ORDER BY row_data), '''')) '
        || 'FROM (SELECT TO_JSONB(q)::TEXT AS row_data FROM ('
        || p_query_sql || ') AS q) AS serialized_rows';
    EXECUTE v_command INTO v_count, v_md5;

    INSERT INTO p2_benchmark.result_signatures
        (stage, scenario, result_count, result_md5)
    VALUES (p_stage, p_scenario, v_count, v_md5)
    ON CONFLICT (stage, scenario) DO UPDATE
       SET result_count = EXCLUDED.result_count,
           result_md5 = EXCLUDED.result_md5;
END;
$$;

CREATE OR REPLACE FUNCTION p2_benchmark.measure_query(
    p_stage TEXT,
    p_scenario TEXT,
    p_query_sql TEXT,
    p_measured_runs INTEGER DEFAULT 7
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_run INTEGER;
    v_plan JSON;
BEGIN
    IF p_measured_runs < 1 THEN
        RAISE EXCEPTION 'p_measured_runs must be at least 1';
    END IF;

    -- Run 0 is a warm-up and is deliberately not stored in the median data.
    FOR v_run IN 0..p_measured_runs LOOP
        EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || p_query_sql
            INTO v_plan;

        IF v_run > 0 THEN
            INSERT INTO p2_benchmark.measurements
                (stage, scenario, run_number, elapsed_ms,
                 shared_hit_blocks, shared_read_blocks, plan_json)
            VALUES (
                p_stage,
                p_scenario,
                v_run,
                (v_plan::JSONB -> 0 ->> 'Execution Time')::NUMERIC,
                COALESCE((v_plan::JSONB -> 0 -> 'Plan'
                    ->> 'Shared Hit Blocks')::BIGINT, 0),
                COALESCE((v_plan::JSONB -> 0 -> 'Plan'
                    ->> 'Shared Read Blocks')::BIGINT, 0),
                v_plan::JSONB
            )
            ON CONFLICT (stage, scenario, run_number) DO UPDATE
               SET elapsed_ms = EXCLUDED.elapsed_ms,
                   shared_hit_blocks = EXCLUDED.shared_hit_blocks,
                   shared_read_blocks = EXCLUDED.shared_read_blocks,
                   plan_json = EXCLUDED.plan_json;
        END IF;
    END LOOP;
END;
$$;

TRUNCATE TABLE p2_benchmark.measurements,
               p2_benchmark.result_signatures;

-- Capture each plan separately in pgAdmin for readable evidence.
-- Screenshot: evidence/baseline-01-customer-account-join.png
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.full_name, a.account_id,
       a.account_number, a.account_type, a.balance
FROM p2_benchmark.customers AS c
JOIN p2_benchmark.accounts AS a USING (customer_id)
WHERE c.customer_id = 12345
ORDER BY a.account_id;

-- Screenshot: evidence/baseline-02-account-type-aggregate.png
EXPLAIN (ANALYZE, BUFFERS)
SELECT account_type, COUNT(*) AS account_count,
       SUM(balance) AS total_balance,
       AVG(balance) AS average_balance
FROM p2_benchmark.accounts
GROUP BY account_type
ORDER BY account_type;

-- Screenshot: evidence/baseline-03-account-transaction-history.png
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_id, account_role, transaction_type,
       amount, status, transaction_date
FROM (
    SELECT transaction_id, 'source'::TEXT AS account_role,
           transaction_type, amount, status, transaction_date
    FROM p2_benchmark.transactions
    WHERE source_account_id = 54321
    UNION ALL
    SELECT transaction_id, 'destination'::TEXT AS account_role,
           transaction_type, amount, status, transaction_date
    FROM p2_benchmark.transactions
    WHERE destination_account_id = 54321
) AS account_history
ORDER BY transaction_date DESC, transaction_id DESC
LIMIT 25;

-- Screenshot: evidence/baseline-04-date-range-report.png
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_type, status, COUNT(*) AS transaction_count,
       SUM(amount) AS total_amount
FROM p2_benchmark.transactions
WHERE transaction_date >= TIMESTAMP '2025-07-01'
  AND transaction_date <  TIMESTAMP '2025-07-08'
GROUP BY transaction_type, status
ORDER BY transaction_type, status;

-- Save result signatures and seven measured runs after one warm-up per query.
SELECT p2_benchmark.capture_result_signature(
    'baseline', 'customer_account_lookup',
    $$SELECT c.customer_id, c.full_name, a.account_id,
             a.account_number, a.account_type, a.balance
      FROM p2_benchmark.customers AS c
      JOIN p2_benchmark.accounts AS a USING (customer_id)
      WHERE c.customer_id = 12345
      ORDER BY a.account_id$$
);
SELECT p2_benchmark.measure_query(
    'baseline', 'customer_account_lookup',
    $$SELECT c.customer_id, c.full_name, a.account_id,
             a.account_number, a.account_type, a.balance
      FROM p2_benchmark.customers AS c
      JOIN p2_benchmark.accounts AS a USING (customer_id)
      WHERE c.customer_id = 12345
      ORDER BY a.account_id$$
);

SELECT p2_benchmark.capture_result_signature(
    'baseline', 'account_type_aggregate',
    $$SELECT account_type, COUNT(*) AS account_count,
             SUM(balance) AS total_balance,
             AVG(balance) AS average_balance
      FROM p2_benchmark.accounts
      GROUP BY account_type
      ORDER BY account_type$$
);
SELECT p2_benchmark.measure_query(
    'baseline', 'account_type_aggregate',
    $$SELECT account_type, COUNT(*) AS account_count,
             SUM(balance) AS total_balance,
             AVG(balance) AS average_balance
      FROM p2_benchmark.accounts
      GROUP BY account_type
      ORDER BY account_type$$
);

SELECT p2_benchmark.capture_result_signature(
    'baseline', 'account_transaction_history',
    $$SELECT transaction_id, account_role, transaction_type,
             amount, status, transaction_date
      FROM (
          SELECT transaction_id, 'source'::TEXT AS account_role,
                 transaction_type, amount, status, transaction_date
          FROM p2_benchmark.transactions
          WHERE source_account_id = 54321
          UNION ALL
          SELECT transaction_id, 'destination'::TEXT AS account_role,
                 transaction_type, amount, status, transaction_date
          FROM p2_benchmark.transactions
          WHERE destination_account_id = 54321
      ) AS account_history
      ORDER BY transaction_date DESC, transaction_id DESC
      LIMIT 25$$
);
SELECT p2_benchmark.measure_query(
    'baseline', 'account_transaction_history',
    $$SELECT transaction_id, account_role, transaction_type,
             amount, status, transaction_date
      FROM (
          SELECT transaction_id, 'source'::TEXT AS account_role,
                 transaction_type, amount, status, transaction_date
          FROM p2_benchmark.transactions
          WHERE source_account_id = 54321
          UNION ALL
          SELECT transaction_id, 'destination'::TEXT AS account_role,
                 transaction_type, amount, status, transaction_date
          FROM p2_benchmark.transactions
          WHERE destination_account_id = 54321
      ) AS account_history
      ORDER BY transaction_date DESC, transaction_id DESC
      LIMIT 25$$
);

SELECT p2_benchmark.capture_result_signature(
    'baseline', 'transaction_date_range',
    $$SELECT transaction_type, status, COUNT(*) AS transaction_count,
             SUM(amount) AS total_amount
      FROM p2_benchmark.transactions
      WHERE transaction_date >= TIMESTAMP '2025-07-01'
        AND transaction_date <  TIMESTAMP '2025-07-08'
      GROUP BY transaction_type, status
      ORDER BY transaction_type, status$$
);
SELECT p2_benchmark.measure_query(
    'baseline', 'transaction_date_range',
    $$SELECT transaction_type, status, COUNT(*) AS transaction_count,
             SUM(amount) AS total_amount
      FROM p2_benchmark.transactions
      WHERE transaction_date >= TIMESTAMP '2025-07-01'
        AND transaction_date <  TIMESTAMP '2025-07-08'
      GROUP BY transaction_type, status
      ORDER BY transaction_type, status$$
);

-- Baseline median summary; one warm-up is excluded from each seven-run median.
-- Screenshot: evidence/baseline-median-summary.png
SELECT stage, scenario, COUNT(*) AS measured_runs,
       ROUND(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY elapsed_ms), 3)
           AS median_execution_ms,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY shared_hit_blocks)
           AS median_shared_hit_blocks,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY shared_read_blocks)
           AS median_shared_read_blocks
FROM p2_benchmark.measurements
WHERE stage = 'baseline'
GROUP BY stage, scenario
ORDER BY scenario;
