-- MIT 8103: Advanced Database Systems
-- Project: SwiftBank Banking Database
-- Portfolio 1: Repeatable sample data for the documented schema
--
-- Run sql/01-create-tables.sql first. This script only inserts the
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

COMMIT;


