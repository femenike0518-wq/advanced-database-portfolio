-- MIT 8103: Advanced Database Systems
-- Project: SwiftBank Banking Database
-- Portfolio 1: Repeatable sample data for the documented schema
--
-- Run CREATE TABLE COMMANDS.sql first. This script only inserts the
-- fictional SwiftBank sample records; it does not delete or reset data.
-- Re-running it is safe because existing rows are matched by the schema's
-- unique email and account_number values.

BEGIN;

INSERT INTO customers (full_name, email, phone)
VALUES
    ('Tosin Amir', 'tosin@test.com', '08030000001'),
    ('Daniel Musa', 'daniel@test.com', '08030000002'),
    ('Grace Bello', 'grace@test.com', '08030000003')
ON CONFLICT (email) DO NOTHING;

-- Resolve customer IDs by their unique email addresses rather than assuming
-- identity values, so the script also works in a database with existing rows.
INSERT INTO accounts (customer_id, account_number, account_type, balance)
SELECT c.customer_id, seed.account_number, seed.account_type, seed.balance
FROM (VALUES
    ('tosin@test.com',  'SWB100001', 'savings', 50000.00::NUMERIC(15, 2)),
    ('daniel@test.com', 'SWB100002', 'current', 80000.00::NUMERIC(15, 2)),
    ('grace@test.com',  'SWB100003', 'savings', 30000.00::NUMERIC(15, 2))
) AS seed(email, account_number, account_type, balance)
JOIN customers AS c ON c.email = seed.email
ON CONFLICT (account_number) DO NOTHING;

-- Sample activity corresponding to the seeded accounts. Dates are fixed so
-- screenshots and query results remain consistent between runs.
INSERT INTO transactions (
    source_account_id,
    destination_account_id,
    transaction_type,
    amount,
    status,
    transaction_date
)
SELECT
    source.account_id,
    destination.account_id,
    seed.transaction_type,
    seed.amount,
    seed.status,
    seed.transaction_date
FROM (VALUES
    (NULL::VARCHAR(20), 'SWB100001', 'deposit',    10000.00::NUMERIC(15, 2), 'completed', TIMESTAMP '2025-01-10 09:00:00'),
    ('SWB100002', NULL::VARCHAR(20), 'withdrawal',  5000.00::NUMERIC(15, 2), 'completed', TIMESTAMP '2025-01-11 10:30:00'),
    ('SWB100001', 'SWB100003',       'transfer',    2500.00::NUMERIC(15, 2), 'completed', TIMESTAMP '2025-01-12 14:15:00')
) AS seed(source_account_number, destination_account_number, transaction_type, amount, status, transaction_date)
LEFT JOIN accounts AS source
    ON source.account_number = seed.source_account_number
LEFT JOIN accounts AS destination
    ON destination.account_number = seed.destination_account_number
WHERE (seed.source_account_number IS NULL OR source.account_id IS NOT NULL)
  AND (seed.destination_account_number IS NULL OR destination.account_id IS NOT NULL)
  AND NOT EXISTS (
      SELECT 1
      FROM transactions AS existing
      WHERE existing.transaction_type = seed.transaction_type
        AND existing.amount = seed.amount
        AND existing.transaction_date = seed.transaction_date
        AND existing.source_account_id IS NOT DISTINCT FROM source.account_id
        AND existing.destination_account_id IS NOT DISTINCT FROM destination.account_id
  );

COMMIT;


