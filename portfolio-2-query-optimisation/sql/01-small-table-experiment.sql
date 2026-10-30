-- MIT 8103: Advanced Database Systems
-- Portfolio 2: repeatable small-table index demonstration.
-- Run in the SwiftBank database after Portfolio 1.
-- This drops/recreates only the index created by this exercise; it does not
-- change the sample rows in public.accounts.

DROP INDEX IF EXISTS public.idx_accounts_balance;

-- 1. BASELINE PLAN: the exercise index is absent.
EXPLAIN ANALYZE
SELECT
    c.full_name,
    a.account_number,
    a.balance
FROM public.customers AS c
JOIN public.accounts AS a
    ON c.customer_id = a.customer_id
WHERE a.balance > 40000;

-- 2. Create the balance index for the after-index comparison.
CREATE INDEX idx_accounts_balance
ON public.accounts (balance);
ANALYZE public.accounts;

-- 3. Compare the plan after creating the index.
EXPLAIN ANALYZE
SELECT
    c.full_name,
    a.account_number,
    a.balance
FROM public.customers AS c
JOIN public.accounts AS a
    ON c.customer_id = a.customer_id
WHERE a.balance > 40000;

-- 4. Inspect the balance filter and the created index.
EXPLAIN ANALYZE
SELECT *
FROM public.accounts
WHERE balance > 40000;

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'accounts';