-- MIT 8103 Portfolio 2: add query indexes and compare with baseline.
-- Run after 04a-baseline-plans-and-measurements.sql.
-- Only objects in p2_benchmark are created or updated here.

DELETE FROM p2_benchmark.measurements WHERE stage = 'indexed';
DELETE FROM p2_benchmark.result_signatures WHERE stage = 'indexed';

CREATE INDEX IF NOT EXISTS p2_accounts_customer_id_idx
    ON p2_benchmark.accounts (customer_id);

-- Covering index candidate for the full account-type aggregate. PostgreSQL
-- may still prefer a sequential scan; that planner choice is a valid result.
CREATE INDEX IF NOT EXISTS p2_accounts_type_balance_idx
    ON p2_benchmark.accounts (account_type) INCLUDE (balance);

CREATE INDEX IF NOT EXISTS p2_transactions_source_history_idx
    ON p2_benchmark.transactions
       (source_account_id, transaction_date DESC, transaction_id DESC)
    INCLUDE (transaction_type, amount, status)
    WHERE source_account_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS p2_transactions_destination_history_idx
    ON p2_benchmark.transactions
       (destination_account_id, transaction_date DESC, transaction_id DESC)
    INCLUDE (transaction_type, amount, status)
    WHERE destination_account_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS p2_transactions_date_report_idx
    ON p2_benchmark.transactions
       (transaction_date, transaction_type, status)
    INCLUDE (amount);

ANALYZE p2_benchmark.accounts;
ANALYZE p2_benchmark.transactions;

-- Capture each plan separately in pgAdmin for readable evidence.
-- Screenshot: evidence/indexed-01-customer-account-join.png
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.full_name, a.account_id,
       a.account_number, a.account_type, a.balance
FROM p2_benchmark.customers AS c
JOIN p2_benchmark.accounts AS a USING (customer_id)
WHERE c.customer_id = 12345
ORDER BY a.account_id;

-- Screenshot: evidence/indexed-02-account-type-aggregate.png
EXPLAIN (ANALYZE, BUFFERS)
SELECT account_type, COUNT(*) AS account_count,
       SUM(balance) AS total_balance,
       AVG(balance) AS average_balance
FROM p2_benchmark.accounts
GROUP BY account_type
ORDER BY account_type;

-- Screenshot: evidence/indexed-03-account-transaction-history.png
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

-- Screenshot: evidence/indexed-04-date-range-report.png
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_type, status, COUNT(*) AS transaction_count,
       SUM(amount) AS total_amount
FROM p2_benchmark.transactions
WHERE transaction_date >= TIMESTAMP '2025-07-01'
  AND transaction_date <  TIMESTAMP '2025-07-08'
GROUP BY transaction_type, status
ORDER BY transaction_type, status;

SELECT p2_benchmark.capture_result_signature(
    'indexed', 'customer_account_lookup',
    $$SELECT c.customer_id, c.full_name, a.account_id,
             a.account_number, a.account_type, a.balance
      FROM p2_benchmark.customers AS c
      JOIN p2_benchmark.accounts AS a USING (customer_id)
      WHERE c.customer_id = 12345
      ORDER BY a.account_id$$
);
SELECT p2_benchmark.measure_query(
    'indexed', 'customer_account_lookup',
    $$SELECT c.customer_id, c.full_name, a.account_id,
             a.account_number, a.account_type, a.balance
      FROM p2_benchmark.customers AS c
      JOIN p2_benchmark.accounts AS a USING (customer_id)
      WHERE c.customer_id = 12345
      ORDER BY a.account_id$$
);

SELECT p2_benchmark.capture_result_signature(
    'indexed', 'account_type_aggregate',
    $$SELECT account_type, COUNT(*) AS account_count,
             SUM(balance) AS total_balance,
             AVG(balance) AS average_balance
      FROM p2_benchmark.accounts
      GROUP BY account_type
      ORDER BY account_type$$
);
SELECT p2_benchmark.measure_query(
    'indexed', 'account_type_aggregate',
    $$SELECT account_type, COUNT(*) AS account_count,
             SUM(balance) AS total_balance,
             AVG(balance) AS average_balance
      FROM p2_benchmark.accounts
      GROUP BY account_type
      ORDER BY account_type$$
);

SELECT p2_benchmark.capture_result_signature(
    'indexed', 'account_transaction_history',
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
    'indexed', 'account_transaction_history',
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
    'indexed', 'transaction_date_range',
    $$SELECT transaction_type, status, COUNT(*) AS transaction_count,
             SUM(amount) AS total_amount
      FROM p2_benchmark.transactions
      WHERE transaction_date >= TIMESTAMP '2025-07-01'
        AND transaction_date <  TIMESTAMP '2025-07-08'
      GROUP BY transaction_type, status
      ORDER BY transaction_type, status$$
);
SELECT p2_benchmark.measure_query(
    'indexed', 'transaction_date_range',
    $$SELECT transaction_type, status, COUNT(*) AS transaction_count,
             SUM(amount) AS total_amount
      FROM p2_benchmark.transactions
      WHERE transaction_date >= TIMESTAMP '2025-07-01'
        AND transaction_date <  TIMESTAMP '2025-07-08'
      GROUP BY transaction_type, status
      ORDER BY transaction_type, status$$
);

-- Screenshot: evidence/benchmark-result-parity.png
SELECT baseline.scenario,
       baseline.result_count AS baseline_rows,
       indexed.result_count AS indexed_rows,
       baseline.result_md5 = indexed.result_md5 AS same_result_set
FROM p2_benchmark.result_signatures AS baseline
JOIN p2_benchmark.result_signatures AS indexed USING (scenario)
WHERE baseline.stage = 'baseline'
  AND indexed.stage = 'indexed'
ORDER BY baseline.scenario;

-- Screenshot: evidence/benchmark-median-summary.png
SELECT stage, scenario, COUNT(*) AS measured_runs,
       ROUND(PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY elapsed_ms), 3)
           AS median_execution_ms,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY shared_hit_blocks)
           AS median_shared_hit_blocks,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY shared_read_blocks)
           AS median_shared_read_blocks
FROM p2_benchmark.measurements
GROUP BY stage, scenario
ORDER BY scenario, stage;

-- Screenshot: evidence/benchmark-index-sizes.png
SELECT indexrelname AS index_name,
       pg_relation_size(indexrelid) AS size_bytes,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'p2_benchmark'
  AND indexrelname LIKE 'p2_%'
ORDER BY indexrelname;
