-- Run after 01-setup-demo-schema.sql.
-- This intentionally demonstrates an unsafe read-then-write lost update.
-- Do not execute the whole file in one session. Run each block separately.

-- Run after the committed transfer. Account 1 begins this demonstration at
-- 4250.00. The stale absolute writes below intentionally show a lost update.
-- SESSION A: read the starting balance (4250.00); leave the transaction open.
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM p3_demo.accounts WHERE account_id = 1;

-- SESSION B: read the same starting balance (4250.00); leave it open too.
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM p3_demo.accounts WHERE account_id = 1;

-- SESSION B: use its earlier read to write 4250 - 150 = 4100, then COMMIT.
UPDATE p3_demo.accounts
SET balance = 4250.00 - 150.00
WHERE account_id = 1;
COMMIT;

-- SESSION A: its earlier read is still 4250. It now writes 4250 - 100 = 4150
-- and commits, overwriting B's committed value. Run UPDATE then COMMIT in A.
UPDATE p3_demo.accounts
SET balance = 4250.00 - 100.00
WHERE account_id = 1;
COMMIT;

-- Verify from a fresh session. Correct if both withdrawals applied: 4000.00.
SELECT account_id, balance,
       4250.00 - 100.00 - 150.00 AS expected_if_both_withdrawals_applied
FROM p3_demo.accounts
WHERE account_id = 1;
