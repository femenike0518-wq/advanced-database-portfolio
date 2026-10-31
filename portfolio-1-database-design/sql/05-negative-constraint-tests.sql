-- MIT 8103 Portfolio 1: negative tests for declared keys, foreign keys and checks.
-- Run after sql/02-seed-data.sql. Each expected database error is caught and
-- printed with PostgreSQL's actual message. The outer transaction is rolled back.
BEGIN;

DO $$
DECLARE
    v_customer_id INTEGER;
    v_account_id INTEGER;
BEGIN
    SELECT customer_id INTO v_customer_id
    FROM customers WHERE email = 'tosin@test.com';

    SELECT account_id INTO v_account_id
    FROM accounts WHERE account_number = 'SWB100001';

    IF v_customer_id IS NULL OR v_account_id IS NULL THEN
        RAISE EXCEPTION 'Run sql/02-seed-data.sql first; required sample rows are missing.';
    END IF;

    BEGIN
        INSERT INTO customers (full_name, email, phone)
        VALUES ('Duplicate Email Test', 'tosin@test.com', '08039990001');
        RAISE NOTICE 'FAIL duplicate email: row was accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS duplicate email rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_type, balance)
        VALUES (v_customer_id, 'SWB100001', 'savings', 100.00);
        RAISE NOTICE 'FAIL duplicate account number: row was accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS duplicate account number rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_type, balance)
        VALUES (v_customer_id, 'P1T-NEG-BALANCE', 'savings', -1.00);
        RAISE NOTICE 'FAIL negative balance: row was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS negative balance rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_type, balance)
        VALUES (v_customer_id, 'P1T-INVALID-TYPE', 'investment', 100.00);
        RAISE NOTICE 'FAIL invalid account type: row was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS invalid account type rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO transactions (destination_account_id, transaction_type, amount, status)
        VALUES (v_account_id, 'deposit', 0.00, 'completed');
        RAISE NOTICE 'FAIL zero amount: row was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS zero amount rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO transactions (destination_account_id, transaction_type, amount, status)
        VALUES (v_account_id, 'deposit', -1.00, 'completed');
        RAISE NOTICE 'FAIL negative amount: row was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS negative amount rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO transactions (source_account_id, destination_account_id, transaction_type, amount, status)
        VALUES (v_account_id, v_account_id, 'deposit', 1.00, 'completed');
        RAISE NOTICE 'FAIL deposit with source account: row was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS deposit with source account rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO transactions (source_account_id, destination_account_id, transaction_type, amount, status)
        VALUES (v_account_id, v_account_id, 'transfer', 1.00, 'completed');
        RAISE NOTICE 'FAIL transfer to same account: row was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS transfer to same account rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_type, balance)
        VALUES (-2147483000, 'P1T-NO-CUSTOMER', 'savings', 100.00);
        RAISE NOTICE 'FAIL missing customer foreign key: row was accepted';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'PASS missing customer foreign key rejected: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO transactions (destination_account_id, transaction_type, amount, status)
        VALUES (-2147483000, 'deposit', 1.00, 'completed');
        RAISE NOTICE 'FAIL missing account foreign key: row was accepted';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'PASS missing account foreign key rejected: %', SQLERRM;
    END;
END
$$;

ROLLBACK;
