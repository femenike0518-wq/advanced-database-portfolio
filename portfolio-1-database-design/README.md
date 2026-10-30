# Portfolio 1: Database Design and Modelling

## Case study

SwiftBank is a fictional banking system. Customers use it to hold savings and current accounts and to make deposits, withdrawals and transfers. Bank staff and administrators maintain customer and account records and review transaction history. The database stores customer contact details, account identifiers and balances, and transaction type, amount, status, date and account references.

## Relational schema

| Table | Primary key | Foreign keys | Main attributes and rules |
| --- | --- | --- | --- |
| `customers` | `customer_id` | None | `full_name`, unique `email`, optional `phone`, `created_at`. |
| `accounts` | `account_id` | `customer_id` → `customers.customer_id` | Unique `account_number`, `account_type` limited to savings/current, nonnegative `balance`, `created_at`. |
| `transactions` | `transaction_id` | Nullable `source_account_id` and `destination_account_id` → `accounts.account_id` | `transaction_type`, positive `amount`, `status`, `transaction_date`. A CHECK rule makes source/destination use depend on transaction type. |

A customer can own multiple accounts; every account belongs to one customer. A transaction can reference accounts in the source and destination roles. A deposit has no source and requires a destination; a withdrawal requires a source and has no destination; a transfer requires two different accounts. Unique, NOT NULL, foreign key and CHECK constraints enforce these rules in PostgreSQL.

## Final ER diagram and normalisation

The final diagram is `evidence/er-diagram-final.png`. It shows customers, accounts and transactions, the customer-to-account relationship, and the optional source and destination account references. Earlier drawings remain labelled as drafts or superseded in `evidence/`.

The design applies 1NF by keeping each field atomic and representing multiple accounts as rows. Each table has a single-column primary key, so the listed non-key attributes depend on the whole key (2NF). Customer, account and transaction facts are kept in their respective tables and connected by foreign keys (3NF), avoiding repeated customer details in each account or transaction. These statements describe the submitted schema; a formal proof would require listing all functional dependencies and candidate keys.

## Seed data and balance reconciliation

The repeatable seed script creates six fictional customers, six accounts (savings and current), and eleven transactions. Each seeded account begins with an opening deposit matching its stored balance. The completed sample deposit/withdrawal and reciprocal transfer activity nets to zero, so the final balances remain equal to the completed ledger. The failed withdrawal records an attempted transaction and does not affect the balance. The sample retains the original three customers/accounts used by the MongoDB portfolio.

## Run order

1. Connect pgAdmin to the SwiftBank database. If the three tables do not already exist, run `sql/01-create-tables.sql` once.
2. Run `sql/02-seed-data.sql`. It inserts only missing sample rows and does not delete or reset existing data.
3. Run `sql/03-join-query.sql` to view customer and account details.
4. Run `sql/04-verify-seed-and-ledger.sql`. Each seeded account should show `balances_match = true`; the second query summarizes transaction types and statuses.
5. Run `sql/05-negative-constraint-tests.sql`. Open the Messages tab to see each rejected invalid row and PostgreSQL's actual error text. The script ends with `ROLLBACK`, so the negative tests leave no rows behind. If any test prints `FAIL`, stop and report it; do not treat the constraints as verified.

## Evidence

- `evidence/er-diagram-final.png` — selected ER diagram.
- `evidence/01-customer-account-results.png`, `evidence/02-database-tables.png`, `evidence/03a-create-customers-accounts.png` and `evidence/03b-create-transactions.png` — existing design and table evidence.
- New evidence captured after running the updated seed and verification scripts: `evidence/04-seed-and-ledger-check.png`, `evidence/05-negative-constraint-tests.png` and `evidence/06-transaction-type-status-summary.png`.
- `database-design-notes.txt` — detailed design and normalisation notes.

## Limitations

This is a small fictional coursework dataset. The SQL constraints validate row-level relationships and values; the examples do not implement a production banking service or a complete accounting ledger.
