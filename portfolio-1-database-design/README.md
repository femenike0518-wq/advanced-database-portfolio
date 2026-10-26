# Portfolio 1: Database Design and Modelling

## Purpose

This practical designs a relational database for the fictional SwiftBank case study. It uses PostgreSQL to represent customers, accounts and transactions as related tables.

## Tools

- PostgreSQL and pgAdmin
- SQL for table definitions, seed data and queries
- ER diagram and screenshots as evidence

## Implementation

The schema creates `customers`, `accounts` and `transactions`. Primary keys identify rows, foreign keys connect related records, and the defined `UNIQUE`, `NOT NULL` and `CHECK` constraints enforce the rules in the schema. The ER diagram documents the relationships, including a customer having multiple accounts. A join query retrieves customer and account information together.

## Recreate the sample records

1. Open the SwiftBank database in pgAdmin's Query Tool.
2. Run `CREATE TABLE COMMANDS.sql` to create the tables. Skip this step only if the tables already exist.
3. Run `seed-data.sql` to add the three fictional customers and their accounts.
4. Run `JOIN QUERY.sql` to view the customer and account records shown in the portfolio screenshots.

The seed script uses the unique customer emails and account numbers to avoid inserting duplicate customer and account rows when run more than once. It does not delete existing records. The sample account balances match the saved join output.

## How it was checked

The SQL was run against the SwiftBank sample database. The table and query screenshots, along with the saved join output, document the resulting tables and joined data. The sample records are fictional.

## Files and evidence

- `CREATE TABLE COMMANDS.sql` — table definitions, keys and constraints.
- `seed-data.sql` — repeatable fictional customer and account records.
- `JOIN QUERY.sql` and `join-query-results.xlsx..csv` — join query and sample output.
- `04-swiftbank-er-diagram.png` and `ER Image.png` — ER diagram evidence.
- `database-design-notes.txt` — case study, relationships and design notes.
- Numbered screenshots — table creation and query results.

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

The corrected ER diagram shows the optional account relationships.
The transaction-type rules must also be enforced by the database
constraints; the diagram alone does not enforce them.

See `swiftbank-er-diagram-corrected.png` for the corrected diagram.
