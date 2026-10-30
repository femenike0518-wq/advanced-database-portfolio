-- MIT 8103: Advanced Database Systems
-- Project: SwiftBank Banking Database
-- Portfolio 1: repeatable, fictional sample data
--
-- Run sql/01-create-tables.sql once if the tables do not already exist.
-- This script only inserts seed rows; it never deletes or resets data.
-- Existing customer/account rows are matched by their unique email/account number.
-- Transaction rows are matched by their full seeded values so reruns do not duplicate them.

BEGIN;

INSERT INTO customers (full_name, email, phone)
VALUES
    ('Tosin Amir', 'tosin@test.com', '08030000001'),
    ('Daniel Musa', 'daniel@test.com', '08030000002'),
    ('Grace Bello', 'grace@test.com', '08030000003'),
    ('Amina Yusuf', 'amina@test.com', '08030000004'),
    ('Emeka Nwosu', 'emeka@test.com', '08030000005'),
    ('Lara Adeyemi', 'lara@test.com', '08030000006')
ON CONFLICT (email) DO NOTHING;

-- Resolve identity keys by email so this works when IDs differ between databases.
INSERT INTO accounts (customer_id, account_number, account_type, balance)
SELECT c.customer_id, seed.account_number, seed.account_type, seed.balance
FROM (VALUES
    ('tosin@test.com',  'SWB100001', 'savings', 50000.00::NUMERIC(15, 2)),
    ('daniel@test.com', 'SWB100002', 'current', 80000.00::NUMERIC(15, 2)),
    ('grace@test.com',  'SWB100003', 'savings', 30000.00::NUMERIC(15, 2)),
    ('amina@test.com',  'SWB100004', 'current', 45000.00::NUMERIC(15, 2)),
    ('emeka@test.com',  'SWB100005', 'savings', 72000.00::NUMERIC(15, 2)),
    ('lara@test.com',   'SWB100006', 'current', 18000.00::NUMERIC(15, 2))
) AS seed(email, account_number, account_type, balance)
JOIN customers AS c ON c.email = seed.email
ON CONFLICT (account_number) DO NOTHING;

-- Opening deposits explain each seeded balance. The completed activity below
-- nets to zero, so the six stored balances remain equal to the completed ledger.
-- The failed withdrawal records an unsuccessful attempt and does not change balance.
WITH seed(source_account_number, destination_account_number, transaction_type,
          amount, status, transaction_date) AS (
    VALUES
        (NULL::VARCHAR, 'SWB100001'::VARCHAR, 'deposit'::VARCHAR, 50000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-01-01 09:00:00'),
        (NULL::VARCHAR, 'SWB100002'::VARCHAR, 'deposit'::VARCHAR, 80000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-01-01 09:05:00'),
        (NULL::VARCHAR, 'SWB100003'::VARCHAR, 'deposit'::VARCHAR, 30000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-01-01 09:10:00'),
        (NULL::VARCHAR, 'SWB100004'::VARCHAR, 'deposit'::VARCHAR, 45000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-01-01 09:15:00'),
        (NULL::VARCHAR, 'SWB100005'::VARCHAR, 'deposit'::VARCHAR, 72000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-01-01 09:20:00'),
        (NULL::VARCHAR, 'SWB100006'::VARCHAR, 'deposit'::VARCHAR, 18000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-01-01 09:25:00'),
        (NULL::VARCHAR, 'SWB100004'::VARCHAR, 'deposit'::VARCHAR, 2500.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-02-01 10:00:00'),
        ('SWB100004'::VARCHAR, NULL::VARCHAR, 'withdrawal'::VARCHAR, 2500.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-02-02 10:00:00'),
        ('SWB100002'::VARCHAR, 'SWB100003'::VARCHAR, 'transfer'::VARCHAR, 1000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-02-03 11:00:00'),
        ('SWB100003'::VARCHAR, 'SWB100002'::VARCHAR, 'transfer'::VARCHAR, 1000.00::NUMERIC(15, 2), 'completed'::VARCHAR, TIMESTAMP '2026-02-04 11:00:00'),
        ('SWB100002'::VARCHAR, NULL::VARCHAR, 'withdrawal'::VARCHAR, 1000000.00::NUMERIC(15, 2), 'failed'::VARCHAR, TIMESTAMP '2026-02-05 12:00:00')
), resolved AS (
    SELECT source.account_id AS source_account_id,
           destination.account_id AS destination_account_id,
           seed.transaction_type,
           seed.amount,
           seed.status,
           seed.transaction_date
    FROM seed
    LEFT JOIN accounts AS source
      ON source.account_number = seed.source_account_number
    LEFT JOIN accounts AS destination
      ON destination.account_number = seed.destination_account_number
    WHERE (seed.source_account_number IS NULL OR source.account_id IS NOT NULL)
      AND (seed.destination_account_number IS NULL OR destination.account_id IS NOT NULL)
)
INSERT INTO transactions
    (source_account_id, destination_account_id, transaction_type, amount, status, transaction_date)
SELECT resolved.source_account_id,
       resolved.destination_account_id,
       resolved.transaction_type,
       resolved.amount,
       resolved.status,
       resolved.transaction_date
FROM resolved
WHERE NOT EXISTS (
    SELECT 1
    FROM transactions AS existing
    WHERE existing.source_account_id IS NOT DISTINCT FROM resolved.source_account_id
      AND existing.destination_account_id IS NOT DISTINCT FROM resolved.destination_account_id
      AND existing.transaction_type = resolved.transaction_type
      AND existing.amount = resolved.amount
      AND existing.status = resolved.status
      AND existing.transaction_date = resolved.transaction_date
);

COMMIT;
