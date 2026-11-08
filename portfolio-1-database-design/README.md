 Portfolio 1: Database Design and Modeling

> AI-use declaration: See the [root README](../README.md#ai-use-declaration).

Case study

SwiftBank: a fictional banking system. Customers use it to make deposits, make withdrawals, make transfers and store savings and current accounts. Bank employees and administrators can review transaction history and keep customer account records. Customer contact information, account identifiers and balances, transaction type, amount, status, date and account references are all stored in the database.

Relational schema

| Table | Primary key | Foreign keys | Main attributes and rules |
| --- | --- | --- | --- |
| `customers` | `customer_id` | None | `full_name`, unique `email`, optional `phone`, `created_at`. |
| `accounts` | `account_id` | `customer_id` → `customers.customer_id` | Unique `account_number`, `account_type` limited to savings/current, nonnegative `balance`, `created_at`. |
| `transactions` | `transaction_id` | Nullable `source_account_id` and `destination_account_id` → `accounts.account_id` | `transaction_type`, positive `amount`, `status`, `transaction_date`. A CHECK rule makes source/destination use depend on transaction type. |

Each account is owned by a single customer who may have more than one account. Accounts in the source and destination roles may be referenced in a transaction. A withdrawal needs a source and a destination; a transfer needs two separate accounts and a deposit has no source and a destination. In PostgresSQL, these rules are enforced by unique, NOT NULL, foreign key and CHECK constraints.

Final ER diagram and normalization

 `evidence/er-diagram-final.png` is the final diagram. Customers, accounts and transactions are shown, along with the customer-to-account relationship and optional source and destination account references. Previous drawings are still marked as drafts or replaced in `evidence/`.

By keeping each field atomic and using rows to represent multiple accounts, the design employs 1NF. The listed non-key attributes rely on the entire key (2NF) because each table has a single-column primary key. In order to prevent duplicate information in each account or transaction, customer, account and transaction facts are stored in their corresponding tables and linked by foreign keys (3NF). These claims outline the submitted schema; a formal proof would need to include a list of all candidate keys and functional dependencies.

Seed data and Balance reconciliation

Six fictitious clients, six accounts (current and savings) and eleven transactions are produced by the repeatable seed script. The opening deposit for each seeded account is equal to the stored balance. The final balances stay the same as the completed ledger because the completed sample deposit/withdrawal and reciprocal transfer activity nets to zero. The unsuccessful withdrawal does not impact the balance; instead, it documents an attempted transaction. The MongoDB portfolio's initial three accounts are kept in the sample.

Run order

1. I link the SwiftBank database to pgAdmin. I run `sql/01-create-tables.sql` once if the three tables don't already exist.
2. I execute `sql/02-seed-data.sql`. It does not remove or reset the current data; it only adds the missing sample rows.
3. To view account and customer information, I execute `sql/03-join-query.sql`.
4. I execute `sql/04-verify-seed-and-ledger.sql`. In my verification, every seeded account displays  `balances_match = true`; the second query provides an overview of transaction types and statuses.
5. I examine PostgresSQL's actual error text in the Messages tab after running `sql/05-negative-constraint-tests.sql`. Because the script ends with `ROLLBACK`, the negative tests leave no rows behind. In my run, every test printed a `PASS`; a `FAIL` line would indicate that the constraint did not function as intended.

Evidence

- `evidence/er-diagram-final.png` — chosen ER diagram.
- `evidence/01-customer-account-results.png`, `evidence/02-database-tables.png`, `evidence/03a-create-customers-accounts.png` and `evidence/03b-create-transactions.png` — existing design and table evidence.
- New evidence captured after running the updated seed and verification scripts: `evidence/04-seed-and-ledger-check.png`, `evidence/05-negative-constraint-tests.png` and `evidence/06-transaction-type-status-summary.png`.
- `database-design-notes.txt` — comprehensive design and normalization notes.

Restrictions

This is a small made-up coursework dataset. Row-level relationships and values are validated by the SQL constraints; neither a full accounting ledger nor a production banking service is implemented in the examples.
