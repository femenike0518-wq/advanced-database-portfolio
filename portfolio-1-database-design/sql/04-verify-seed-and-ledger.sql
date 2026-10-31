-- MIT 8103 Portfolio 1: check seeded account balances against completed ledger rows.
-- Failed attempts are intentionally excluded because they do not move funds.
SELECT a.account_number,
       a.account_type,
       a.balance AS stored_balance,
       COALESCE(SUM(t.amount) FILTER (
           WHERE t.status = 'completed'
             AND t.destination_account_id = a.account_id
       ), 0)
       - COALESCE(SUM(t.amount) FILTER (
           WHERE t.status = 'completed'
             AND t.source_account_id = a.account_id
       ), 0) AS completed_ledger_balance,
       a.balance =
       COALESCE(SUM(t.amount) FILTER (
           WHERE t.status = 'completed'
             AND t.destination_account_id = a.account_id
       ), 0)
       - COALESCE(SUM(t.amount) FILTER (
           WHERE t.status = 'completed'
             AND t.source_account_id = a.account_id
       ), 0) AS balances_match
FROM accounts AS a
LEFT JOIN transactions AS t
  ON t.source_account_id = a.account_id
  OR t.destination_account_id = a.account_id
WHERE a.account_number IN ('SWB100001', 'SWB100002', 'SWB100003', 'SWB100004', 'SWB100005', 'SWB100006')
GROUP BY a.account_id, a.account_number, a.account_type, a.balance
ORDER BY a.account_number;

SELECT transaction_type, status, COUNT(*) AS transaction_count
FROM transactions
WHERE transaction_date >= TIMESTAMP '2026-01-01 00:00:00'
  AND transaction_date < TIMESTAMP '2026-03-01 00:00:00'
GROUP BY transaction_type, status
ORDER BY transaction_type, status;
