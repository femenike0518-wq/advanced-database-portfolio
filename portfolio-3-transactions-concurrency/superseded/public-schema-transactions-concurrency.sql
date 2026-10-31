
-- MIT 8103: Advanced Database Systems
-- Portfolio 3: Transactions and Concurrency
-- Case Study: SwiftBank
-- Database: swiftbank

-- =====================================================
-- 1. ROLLBACK DEMONSTRATION
-- =====================================================
-- Temporarily increase account 1's balance by 100.
-- ROLLBACK cancels the uncommitted change.

BEGIN;

UPDATE accounts
SET balance = balance + 100
WHERE account_id = 1;

-- View the temporary balance inside the transaction.
SELECT account_id, account_number, balance
FROM accounts
WHERE account_id = 1;

ROLLBACK;

-- Verify that the original balance is restored.
SELECT account_id, account_number, balance
FROM accounts
WHERE account_id = 1;


-- =====================================================
-- 2. BASIC COMMIT DEMONSTRATION
-- =====================================================
-- This update leaves the email unchanged.
-- A stronger visible COMMIT test follows in Section 7.

BEGIN;

UPDATE customers
SET email = email
WHERE customer_id = 1;

COMMIT;

SELECT customer_id, full_name, email
FROM customers
WHERE customer_id = 1;


-- =====================================================
-- 3. CHECK TRANSACTION ISOLATION LEVEL
-- =====================================================

SHOW transaction_isolation;


-- =====================================================
-- 4. CONCURRENCY TEST: SESSION A
-- =====================================================
-- Run this section in Session A only.
-- Leave the transaction open while testing Session B.

BEGIN;

UPDATE accounts
SET balance = balance + 100
WHERE account_id = 1;

-- Session A should see 50100.00 before rollback.
SELECT account_id, account_number, balance
FROM accounts
WHERE account_id = 1;

-- STOP HERE.
-- Do not COMMIT or ROLLBACK until Session B has been tested.


-- =====================================================
-- 5. CONCURRENCY TEST: SESSION B
-- =====================================================
-- Run this SELECT in a separate Query Tool session
-- while Session A's transaction remains open.
-- Session B should see the committed balance: 50000.00.

SELECT account_id, account_number, balance
FROM accounts
WHERE account_id = 1;


-- =====================================================
-- 6. ROLLBACK THE CONCURRENCY TEST
-- =====================================================
-- Return to Session A and run this section.

ROLLBACK;

-- Verify the original balance is still 50000.00.
SELECT account_id, account_number, balance
FROM accounts
WHERE account_id = 1;


-- =====================================================
-- 7. VISIBLE COMMIT DEMONSTRATION
-- =====================================================
-- Temporarily change Tosin Amir's email and commit it.
-- This assumes customer_id 1 is Tosin Amir.

BEGIN;

UPDATE customers
SET email = 'tosin.commit.test@example.com'
WHERE customer_id = 1;

-- View the temporary change before committing.
SELECT customer_id, full_name, email
FROM customers
WHERE customer_id = 1;

COMMIT;

-- Verify the committed email.
SELECT customer_id, full_name, email
FROM customers
WHERE customer_id = 1;


-- =====================================================
-- 8. RESTORE THE ORIGINAL EMAIL
-- =====================================================
-- The original email recorded in our earlier screenshot
-- was tosin@test.com.

BEGIN;

UPDATE customers
SET email = 'tosin@test.com'
WHERE customer_id = 1;

COMMIT;

-- Verify that the original email has been restored.
SELECT customer_id, full_name, email
FROM customers
WHERE customer_id = 1;
