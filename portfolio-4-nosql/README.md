# Portfolio 4: NoSQL and Advanced Data Models

## Purpose

This practical models SwiftBank customer data in MongoDB and considers how embedded account details differ from the relational design in Portfolio 1.

## Tools

- MongoDB Community Server
- MongoDB Compass
- MongoDB shell commands in JavaScript format

## Folder layout

- `mongodb/` — document insert and query commands
- `evidence/` — Compass screenshots
- `nosql-design-notes.txt` — document model, suitability and considerations

## Implementation

The `swiftbank_nosql` database contains a `customers` collection. Customer documents include an embedded `accounts` array. The command script inserts and reads sample documents, updates sample email values, projects selected fields and queries customers with savings accounts.

## How it was checked

The screenshots document the connection, database and customer documents, embedded account details, savings-account query and final verification. The design notes discuss why embedding is convenient for retrieving one customer's account details together in this example.

## Files and evidence

- `mongodb/01-swiftbank-documents.js` — database, document and query commands.
- `nosql-design-notes.txt` — document model, suitability and considerations.
- `evidence/01-mongodb-connection.png` through `evidence/07b-final-customer-verification.png` — connection, documents, embedded accounts, query and verification.

## Limitations

This is a small coursework example, not a complete banking implementation. It does not evaluate production security, transaction design or concurrent account updates. The notes discuss these concerns as design considerations.
