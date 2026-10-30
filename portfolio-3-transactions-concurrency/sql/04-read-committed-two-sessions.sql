-- Run after 01-setup-demo-schema.sql.
-- Do not execute the whole file in one session. Run each marked block in the
-- named Query Tool session, keeping Session A's transaction open as directed.

-- SESSION A: begin an uncommitted balance change; leave this transaction open.
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE p3_demo.accounts
SET balance = balance + 100.00
WHERE account_id = 2
RETURNING account_id, balance;

-- SESSION B: while A is still open, run this query. B should see 3250.00,
-- the committed balance after the preceding transfer.
SHOW transaction_isolation;
SELECT account_id, balance
FROM p3_demo.accounts
WHERE account_id = 2;

-- SESSION A: after capturing B's result, cancel A and verify the original value.
ROLLBACK;
SELECT account_id, balance
FROM p3_demo.accounts
WHERE account_id = 2;
