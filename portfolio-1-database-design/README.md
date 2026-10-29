# Portfolio 1: Database Design and Modelling

## Purpose

This practical designs a relational database for the fictional SwiftBank case study. It uses PostgreSQL to represent customers, accounts and transactions as related tables.

## Tools

- PostgreSQL and pgAdmin
- SQL for table definitions, seed data and queries
- ER diagram and screenshots as evidence

## Folder layout

- `sql/` — scripts in run order
- `evidence/` — screenshots, the join-query result file, and ER diagrams
- `database-design-notes.txt` — case study, relationships and design notes

## Implementation

The schema creates `customers`, `accounts` and `transactions`. Primary keys identify rows, foreign keys connect related records, and the defined `UNIQUE`, `NOT NULL` and `CHECK` constraints enforce the rules in the schema. The ER diagram documents the relationships, including a customer having multiple accounts. A join query retrieves customer and account information together.

## Which ER diagram is final

The final ER diagram is `evidence/er-diagram-final.png` (renamed from `swiftbank-er-diagram-corrected.png`). It shows the optional source and destination account relationships on `transactions`.

Earlier drawings are kept only as superseded drafts:

- `evidence/er-diagram-draft.png`
- `evidence/er-diagram-draft-alt.png`
- `evidence/er-diagram-superseded.png`

## Recreate the sample records

1. Open the SwiftBank database in pgAdmin's Query Tool.
2. Run `sql/01-create-tables.sql` to create the tables. Skip this step only if the tables already exist.
3. Run `sql/02-seed-data.sql` to add the three fictional customers and their accounts.
4. Run `sql/03-join-query.sql` to view the customer and account records shown in the portfolio screenshots.

The seed script uses the unique customer emails and account numbers to avoid inserting duplicate customer and account rows when run more than once. It does not delete existing records. The sample account balances match the saved join output.

## How it was checked

The SQL was run against the SwiftBank sample database. The table and query screenshots, along with the saved join output, document the resulting tables and joined data. The sample records are fictional.

## Files and evidence

- `sql/01-create-tables.sql` — table definitions, keys and constraints.
- `sql/02-seed-data.sql` — repeatable fictional customer and account records.
- `sql/03-join-query.sql` — customer–account join used in the screenshots.
- `join-query-results.xlsx..csv` — saved join output (this filename is still waiting to be renamed to `evidence/join-query-results.csv` because Excel currently has the file open).
- `evidence/er-diagram-final.png` — final ER diagram.
- `evidence/01-customer-account-results.png`, `evidence/02-database-tables.png`, `evidence/03a-create-customers-accounts.png`, `evidence/03b-create-transactions.png` — table creation and query screenshots.
- `database-design-notes.txt` — case study, relationships and design notes.

## Scope

This is a coursework design using sample data. It demonstrates the documented schema and relationships; it is not a production banking system.


## Transaction Account Relationships

The `transactions` table references the `accounts` table through
`source_account_id` and `destination_account_id`. These are foreign keys
to `accounts.account_id`. Their use depends on the transaction type.

- **Deposit:** `source_account_id` is NULL because the funds enter the
  destination account. `destination_account_id` is required.
- **Withdrawal:** `source_account_id` is required because the funds leave
  that account. `destination_account_id` is NULL.
- **Transfer:** Both account IDs are required, and the source and
  destination accounts must be different.

The final ER diagram shows the optional account relationships.
The transaction-type rules must also be enforced by the database
constraints; the diagram alone does not enforce them.

See `evidence/er-diagram-final.png` for the corrected diagram.

## Normalisation

The design applies the main ideas of 1NF, 2NF and 3NF to keep customer, account and transaction facts organised:

- **First Normal Form (1NF):** Each column stores one value for each row. For example, an account has one `account_number` and one `account_type` in `accounts`; a customer's multiple accounts are stored as separate rows linked by `customer_id`, rather than as repeating account columns in `customers`. In `transactions`, the source and destination are separate account ID columns, each holding one ID or `NULL` as required by the transaction type.
- **Second Normal Form (2NF):** Each table uses a single-column primary key (`customer_id`, `account_id` or `transaction_id`). The other columns in each table describe the row identified by that key, so there are no partial dependencies on part of a composite primary key in this design. For example, `amount`, `status` and `transaction_date` describe the transaction identified by `transaction_id`.
- **Third Normal Form (3NF):** Customer details are kept in `customers`, account details in `accounts`, and transaction details in `transactions`; foreign keys connect these records. For example, `full_name` and `email` are stored with `customer_id` in `customers`, rather than copied into every account or transaction. If a customer's email changes, it can be updated in one customer row instead of in multiple related rows. This separation avoids that repeated-data update problem and keeps each table's non-key facts about its own entity.

These examples describe how the submitted schema is organised. A formal proof of a normal form would require stating and checking all functional dependencies and candidate keys; the table structure alone does not establish every possible dependency.
