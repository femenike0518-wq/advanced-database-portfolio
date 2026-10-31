-- Run after the setup and committed transfer. Account 3 has only 100.00.
-- Run BEGIN and UPDATE together, then inspect the check-constraint error.
-- The failed UPDATE leaves this session's transaction aborted. Run ROLLBACK
-- by itself before running the verification query below.
BEGIN;
UPDATE p3_demo.accounts
SET balance = balance - 750.00
WHERE account_id = 3;

-- After the error, run this command by itself:
-- ROLLBACK;

-- Run these verification queries individually after rollback.
SELECT account_id, account_number, balance
FROM p3_demo.accounts
WHERE account_id IN (2, 3)
ORDER BY account_id;

SELECT COUNT(*) AS transfer_rows_for_rejected_attempt
FROM p3_demo.transactions
WHERE source_account_id = 3
  AND destination_account_id = 2
  AND transaction_type = 'transfer'
  AND amount = 750.00;
