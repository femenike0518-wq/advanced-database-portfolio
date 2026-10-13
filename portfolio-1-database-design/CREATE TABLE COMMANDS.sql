
-- MIT 8103: Advanced Database Systems
-- Project: SwiftBank Banking Database
-- Portfolio 1: Database Design and Modelling

-- Table 1: Customers
CREATE TABLE customers (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: Accounts
CREATE TABLE accounts (
    account_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type VARCHAR(20) NOT NULL
        CHECK (account_type IN ('savings', 'current')),
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0
        CHECK (balance >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

-- Table 3: Transactions
CREATE TABLE transactions (
    transaction_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_account_id INTEGER REFERENCES accounts(account_id),
    destination_account_id INTEGER REFERENCES accounts(account_id),
    transaction_type VARCHAR(20) NOT NULL
        CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'completed'
        CHECK (status IN ('pending', 'completed', 'failed')),
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_transaction_accounts CHECK (
        (transaction_type = 'deposit'
            AND source_account_id IS NULL
            AND destination_account_id IS NOT NULL)
        OR
        (transaction_type = 'withdrawal'
            AND source_account_id IS NOT NULL
            AND destination_account_id IS NULL)
        OR
        (transaction_type = 'transfer'
            AND source_account_id IS NOT NULL
            AND destination_account_id IS NOT NULL
            AND source_account_id <> destination_account_id)
    )
);
