-- MIT 8103 Portfolio 2: isolated, repeatable benchmark data.
-- This script drops and recreates ONLY the p2_benchmark schema.
-- Do not store unrelated objects in that schema. It does not change public tables.

DROP SCHEMA IF EXISTS p2_benchmark CASCADE;
CREATE SCHEMA p2_benchmark;

CREATE TABLE p2_benchmark.customers (
    customer_id BIGINT PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

CREATE TABLE p2_benchmark.accounts (
    account_id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL
        REFERENCES p2_benchmark.customers(customer_id),
    account_number TEXT NOT NULL UNIQUE,
    account_type TEXT NOT NULL
        CHECK (account_type IN ('savings', 'current')),
    balance NUMERIC(15, 2) NOT NULL CHECK (balance >= 0)
);

CREATE TABLE p2_benchmark.transactions (
    transaction_id BIGINT PRIMARY KEY,
    source_account_id BIGINT
        REFERENCES p2_benchmark.accounts(account_id),
    destination_account_id BIGINT
        REFERENCES p2_benchmark.accounts(account_id),
    transaction_type TEXT NOT NULL
        CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL CHECK (status IN ('completed', 'failed')),
    transaction_date TIMESTAMP NOT NULL,
    CONSTRAINT p2_transaction_endpoints_chk CHECK (
        (transaction_type = 'deposit'
            AND source_account_id IS NULL
            AND destination_account_id IS NOT NULL)
        OR
        (transaction_type = 'withdrawal'
            AND source_account_id IS NOT NULL
            AND destination_account_id IS NULL)
        OR
        (transaction_type = 'transfer'
            AND source_account_id IS NOT NULL
            AND destination_account_id IS NOT NULL
            AND source_account_id <> destination_account_id)
    )
);

-- Deterministic fictional rows: 50,000 customers and two accounts each.
INSERT INTO p2_benchmark.customers (customer_id, full_name, email)
SELECT g,
       'Customer ' || LPAD(g::TEXT, 6, '0'),
       'customer' || LPAD(g::TEXT, 6, '0') || '@example.test'
FROM generate_series(1, 50000) AS g;

INSERT INTO p2_benchmark.accounts
    (account_id, customer_id, account_number, account_type, balance)
SELECT g,
       ((g - 1) / 2) + 1,
       'SWP' || LPAD(g::TEXT, 8, '0'),
       CASE WHEN g % 10 < 7 THEN 'savings' ELSE 'current' END,
       (100000 + ((g * 7919) % 5000000))::NUMERIC / 100
FROM generate_series(1, 100000) AS g;

-- Evenly distributed fictional activity across one year. A small share is
-- marked failed so the status column has more than one value for reports.
WITH generated AS (
    SELECT g,
           ((g::BIGINT * 7919) % 100000) + 1 AS source_id,
           ((g::BIGINT * 104729 + 17) % 100000) + 1 AS candidate_destination_id,
           CASE g % 3
               WHEN 0 THEN 'deposit'
               WHEN 1 THEN 'withdrawal'
               ELSE 'transfer'
           END AS transaction_type
    FROM generate_series(1, 500000) AS g
)
INSERT INTO p2_benchmark.transactions
    (transaction_id, source_account_id, destination_account_id,
     transaction_type, amount, status, transaction_date)
SELECT g,
       CASE WHEN transaction_type = 'deposit'
            THEN NULL ELSE source_id END,
       CASE WHEN transaction_type = 'withdrawal'
            THEN NULL
            WHEN transaction_type = 'transfer'
                 AND candidate_destination_id = source_id
            THEN (candidate_destination_id % 100000) + 1
            ELSE candidate_destination_id
       END,
       transaction_type,
       (100 + ((g * 53) % 100000))::NUMERIC / 100,
       CASE WHEN g % 100 = 0 THEN 'failed' ELSE 'completed' END,
       TIMESTAMP '2025-01-01'
           + (((g * 37) % 365)::INTEGER * INTERVAL '1 day')
           + (((g * 197) % 86400)::INTEGER * INTERVAL '1 second')
FROM generated;

-- Refresh planner statistics after loading the synthetic benchmark rows.
ANALYZE p2_benchmark.customers;
ANALYZE p2_benchmark.accounts;
ANALYZE p2_benchmark.transactions;

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM p2_benchmark.customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM p2_benchmark.accounts
UNION ALL
SELECT 'transactions', COUNT(*) FROM p2_benchmark.transactions
ORDER BY table_name;
