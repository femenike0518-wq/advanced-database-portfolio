# Portfolio 4: NoSQL and Advanced Data Models

> AI-use declaration: See the [root README](../README.md#ai-use-declaration).

## Purpose and case study

I model the same fictional SwiftBank customers and accounts used in Portfolio 1. The MongoDB `customers` collection embeds each customer's account details so they can be read together in one document.

## Environment

- MongoDB Community Server 9.0.4 on `localhost:27017`
- MongoDB Compass for database inspection; standalone MongoDB Shell (`mongosh`) 2.14.1 for running the saved scripts
- Database: `swiftbank_nosql`; collection: `customers`

## Safe setup and run order

The setup script drops and recreates only the `swiftbank_nosql` database. It does not change PostgreSQL or any other MongoDB database. I reserve that database name for this exercise.

I run the scripts serially from PowerShell with the standalone MongoDB Shell. In my Windows setup, I extracted the shell executable to the Downloads folder. I start with this command:

```powershell
& "C:\Users\USER\Downloads\mongosh-2.14.1-win32-x64\mongosh-2.14.1-win32-x64\bin\mongosh.exe" "mongodb://127.0.0.1:27017/swiftbank_nosql" --file "C:\Users\USER\Documents\advanced-database-portfolio\portfolio-4-nosql\mongodb\01-swiftbank-documents.js"
```

I run the remaining files with the same executable and connection string, changing the `--file` path to each script in order:

1. I run `mongodb/01-swiftbank-documents.js` to recreate the demo database, add the JSON Schema validator and unique indexes, and insert three repeatable customer documents.
2. I run `mongodb/02-embedded-account-queries.js` to inspect embedded accounts and find customers with savings accounts.
3. I run `mongodb/03-account-type-aggregation.js` to count accounts and sum balances by type.
4. I run `mongodb/04-indexed-email-explain.js` to inspect the collection validator and indexes, then check `explain("executionStats")` for the unique-email lookup.
5. I run `mongodb/05-invalid-document-test.js` once to demonstrate that the validator rejects an unsupported account type. The expected validation error is intentional; this does not insert a document.
## Model and results

The three inserted customers, canonical emails, account numbers, account types and balances match the repeatable P1 seed data. Account balances use BSON `Decimal128`, not JavaScript binary floating-point numbers. Each customer document also has a `recent_transactions` array with a validator limit of five items. I populated it from the P1 seed rows involving these three accounts. The array records the transaction type, Decimal128 amount, date, status, direction and, for transfers, the counterparty account number. I include the seeded failed withdrawal with `status: "failed"`; it records an unsuccessful attempt and does not change the balance.

The two seeded transfers between SWB100002 and SWB100003 move 1,000.00 in each direction. Their net effect is zero, so the embedded final balances of 80,000.00 and 30,000.00 still match the final P1 balances. SWB100001 remains at 50,000.00.

The validator requires the key customer and account fields, checks the allowed account types, and requires decimal balances. Unique indexes protect `customer_id` and `email`. The query scripts show the embedded account lookup, savings-account filter, account-type aggregate, and indexed email query plan.

## Evidence

The earlier screenshots `evidence/01-...` through `evidence/07b-...` document the original prototype, which used numeric balances and in-place email updates. They are retained as historical evidence and are not proof of the revised validator or Decimal128 model.

I recaptured the updated evidence from my local MongoDB Community Server 9.0.4 using standalone mongosh:

- `evidence/08-decimal128-customer-document.png`, `evidence/08-decimal128-customer-document-b.png` and `evidence/08-decimal128-customer-document-c.png` — all three customer documents with their embedded Decimal128 balances and recent transactions.
- `evidence/09-embedded-account-queries.png` and `evidence/09-embedded-account-queries-b.png` through `evidence/09-embedded-account-queries-d.png` — the embedded-account query output across four captures, including the recent transaction arrays. `evidence/09b-savings-account-query.png` retains the earlier savings-account query capture.
- `evidence/10-account-type-aggregation.png` — counts and Decimal128 totals by account type.
- `evidence/11-validator-and-unique-indexes.png` and `evidence/11-validator-and-unique-indexes-b.png` through `evidence/11-validator-and-unique-indexes-d.png` — both unique indexes and the full current collection validator, including the recent-transaction status and direction fields.
- `evidence/12-email-index-execution-stats.png` — the email lookup plan and execution statistics.
- `evidence/13-invalid-document-rejected.png` — actual validation error for the invalid account type.

These captures document my local results only. This collection has three documents, so its explain output demonstrates the selected index but cannot establish a meaningful performance improvement.

## Suitability and limitations

Embedding account details fits a customer view that commonly retrieves the customer and their accounts together. A bank's transaction ledger can grow without bound, so I would normally reference full transaction history from a separate transaction collection rather than continually expanding the customer document. The five-item array demonstrates a bounded recent-history option, populated here with the matching P1 seed rows, including the failed withdrawal marked by status.

The PostgreSQL database remains authoritative for balances and money movement. Copying balances into MongoDB creates a risk of stale or conflicting values unless a reliable synchronization design is added. Money transfers require atomic debit, credit and ledger writes, which this small customer-document example does not implement.

I chose a document model to demonstrate embedded customer-account reads. A key-value store would fit direct key lookups or caching, a wide-column store is aimed at large distributed write and analytical workloads, and a graph model is useful when relationship traversal is central; none is needed for this small coursework example.

## References

- [MongoDB Manual: JSON Schema validation](https://www.mongodb.com/docs/manual/reference/operator/query/jsonschema/)
- [MongoDB Shell: BSON data types and Decimal128](https://www.mongodb.com/docs/mongodb-shell/reference/data-types/)
- [MongoDB Manual: unique indexes](https://www.mongodb.com/docs/manual/core/index-unique/)
- [MongoDB Manual: explain and execution statistics](https://www.mongodb.com/docs/manual/reference/command/explain/)
