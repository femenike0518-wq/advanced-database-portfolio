-- Run after 01-setup-demo-schema.sql.
-- Re-run 01 first to restore the deterministic starting balances.

-- Capture this query before the transfer for the before-state screenshot.
SELECT account_id, account_number, balance
FROM p3_demo.accounts
WHERE account_id IN (1, 2)
ORDER BY account_id;

-- Run this block once after the setup. It is guarded against an accidental
-- repeat so the balances cannot be debited twice by rerunning the same SQL.
DO $$
DECLARE
    affected_rows INTEGER;
BEGIN
    IF EXISTS (
        SELECT 1 FROM p3_demo.transactions
        WHERE source_account_id = 1
          AND destination_account_id = 2
          AND transaction_type = 'transfer'
          AND amount = 750.00
    ) THEN
        RAISE EXCEPTION 'This demo transfer is already recorded; reset p3_demo before retrying.';
    END IF;

    UPDATE p3_demo.accounts
    SET balance = balance - 750.00
    WHERE account_id = 1 AND balance >= 750.00;
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    IF affected_rows <> 1 THEN
        RAISE EXCEPTION 'Transfer stopped: source account is missing or has insufficient funds.';
    END IF;

    UPDATE p3_demo.accounts
    SET balance = balance + 750.00
    WHERE account_id = 2;
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    IF affected_rows <> 1 THEN
        RAISE EXCEPTION 'Transfer stopped: destination account is missing.';
    END IF;

    INSERT INTO p3_demo.transactions
        (source_account_id, destination_account_id, transaction_type, amount)
    VALUES (1, 2, 'transfer', 750.00);
END;
$$;

-- Run these result queries individually for the after-state and ledger screenshots.
SELECT account_id, account_number, balance
FROM p3_demo.accounts
WHERE account_id IN (1, 2)
ORDER BY account_id;

SELECT transaction_id, source_account_id, destination_account_id,
       transaction_type, amount
FROM p3_demo.transactions
ORDER BY transaction_id;
