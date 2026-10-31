-- MIT 8103 Portfolio 3: isolated transaction and concurrency demonstrations.
-- Safe scope: this script drops and recreates only the p3_demo schema.
-- Do not store unrelated objects in p3_demo.

DROP SCHEMA IF EXISTS p3_demo CASCADE;
CREATE SCHEMA p3_demo;

CREATE TABLE p3_demo.customers (
    customer_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

CREATE TABLE p3_demo.accounts (
    account_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES p3_demo.customers (customer_id),
    account_number TEXT NOT NULL UNIQUE,
    account_type TEXT NOT NULL CHECK (account_type IN ('current', 'savings')),
    balance NUMERIC(12, 2) NOT NULL CHECK (balance >= 0)
);

CREATE TABLE p3_demo.transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_account_id INTEGER REFERENCES p3_demo.accounts (account_id),
    destination_account_id INTEGER REFERENCES p3_demo.accounts (account_id),
    transaction_type TEXT NOT NULL
        CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (source_account_id IS NULL OR destination_account_id IS NULL
           OR source_account_id <> destination_account_id)
);

INSERT INTO p3_demo.customers (customer_id, full_name, email) VALUES
    (1, 'Amina Bello', 'amina.bello@example.test'),
    (2, 'Daniel Okafor', 'daniel.okafor@example.test'),
    (3, 'Tomi Adeyemi', 'tomi.adeyemi@example.test');

-- Account 3 is deliberately low-funded for the insufficient-funds example.
INSERT INTO p3_demo.accounts
    (account_id, customer_id, account_number, account_type, balance) VALUES
    (1, 1, 'SB-P3-1001', 'savings', 5000.00),
    (2, 2, 'SB-P3-1002', 'current', 2500.00),
    (3, 3, 'SB-P3-1003', 'savings', 100.00);

SELECT account_id, customer_id, account_number, account_type, balance
FROM p3_demo.accounts
ORDER BY account_id;
