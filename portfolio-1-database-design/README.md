# Portfolio 1: Database Design and Modelling

## Purpose

This practical designs a relational database for the fictional SwiftBank case study. It uses PostgreSQL to represent customers, accounts and transactions as related tables.

## Tools

- PostgreSQL and pgAdmin
- SQL for table definitions and queries
- ER diagram and screenshots as evidence

## Implementation

The schema creates `customers`, `accounts` and `transactions`. Primary keys identify rows, foreign keys connect related records, and the defined `UNIQUE`, `NOT NULL` and `CHECK` constraints enforce the rules in the schema. The ER diagram documents the relationships, including a customer having multiple accounts. A join query retrieves customer and account information together.

## How it was checked

The SQL was run against the SwiftBank sample database. The table and query screenshots, along with the saved join output, document the resulting tables and joined data. The sample records are fictional.

## Files and evidence

- `CREATE TABLE COMMANDS.sql` — table definitions, keys and constraints.
- `JOIN QUERY.sql` and `join-query-results.xlsx..csv` — join query and sample output.
- `04-swiftbank-er-diagram.png` and `ER Image.png` — ER diagram evidence.
- `database-design-notes.txt` — case study, relationships and design notes.
- Numbered screenshots — table creation and query results.

## Scope

This is a coursework design using sample data. It demonstrates the documented schema and relationships; it is not a production banking system.
