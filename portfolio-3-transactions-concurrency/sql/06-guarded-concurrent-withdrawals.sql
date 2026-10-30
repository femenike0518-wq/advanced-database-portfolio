-- Run after 01-setup-demo-schema.sql.
-- The atomic guarded UPDATE prevents the lost update and blocks overdrafts.
-- Do not execute the whole file in one session. Run each block separately.

-- Run after the lost-update demonstration, when account 1 is 4150.00.
-- SESSION A: run the update and leave the transaction open (balance 4050).
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE p3_demo.accounts
SET balance = balance - 100.00
WHERE account_id = 1
  AND balance >= 100.00
RETURNING account_id, balance;

-- SESSION B: run this while A is open. It waits for A's row lock.
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE p3_demo.accounts
SET balance = balance - 150.00
WHERE account_id = 1
  AND balance >= 150.00
RETURNING account_id, balance;

-- SESSION A: commit to release the row lock; B's waiting UPDATE then proceeds.
COMMIT;

-- SESSION B: after its UPDATE returns 3900.00, commit and verify.
COMMIT;
SELECT account_id, balance,
       4150.00 - 100.00 - 150.00 AS expected_after_both_withdrawals
FROM p3_demo.accounts
WHERE account_id = 1;
