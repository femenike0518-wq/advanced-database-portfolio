
-- MIT 8103: Advanced Database Systems
-- Portfolio 2: Query Processing and Optimisation
-- Database: SwiftBank
-- These commands have been run during the practical exercise.

-- 1. BASELINE EXECUTION PLAN
-- Test the original JOIN query before creating the balance index.

EXPLAIN ANALYZE
SELECT
    c.full_name,
    a.account_number,
    a.balance
FROM customers AS c
JOIN accounts AS a
    ON c.customer_id = a.customer_id
WHERE a.balance > 40000;


-- 2. CREATE AN INDEX ON ACCOUNT BALANCE

CREATE INDEX idx_accounts_balance
ON accounts (balance);


-- 3. EXECUTION PLAN AFTER CREATING THE INDEX
-- Compare this plan with the baseline plan.

EXPLAIN ANALYZE
SELECT
    c.full_name,
    a.account_number,
    a.balance
FROM customers AS c
JOIN accounts AS a
    ON c.customer_id = a.customer_id
WHERE a.balance > 40000;


-- 4. EXECUTION PLAN FOR THE BALANCE FILTER ALONE

EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE balance > 40000;


-- 5. VERIFY THE INDEXES ON THE ACCOUNTS TABLE

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'accounts';
