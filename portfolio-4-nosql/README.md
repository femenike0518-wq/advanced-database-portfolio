Portfolio 4: NoSQL and Advanced Data Models

> AI-use declaration: See the [root README](../README.md#ai-use-declaration).

Purpose and case study

I simulate the same made-up SwiftBank clients and accounts from Portfolio 1. Each customer's account details are embedded in the MongoDB `customers` collection so they can be read collectively in a single document.

Environment

- MongoDB Community Server 9.0.4 on `localhost:27017`
- MongoDB Compass for database analysis; standalone MongoDB Shell (`mongosh`) 2.14.1 to execute the scripts that have been saved
- Database: `swiftbank_nosql`; collection: `customers`

Safe setup and run order

Only the `swiftbank_nosql` database is dropped and recreated by the setup script. Neither PostgreSQL nor any other MongoDB database is affected. For this exercise, I set aside that database name.

I use the standalone MongoDB Shell and PowerShell to run the scripts serially. I extracted the shell executable to the Downloads folder in my Windows configuration. I begin by issuing this command:

```powershell
& "C:\Users\USER\Downloads\mongosh-2.14.1-win32-x64\mongosh-2.14.1-win32-x64\bin\mongosh.exe" "mongodb://127.0.0.1:27017/swiftbank_nosql" --file "C:\Users\USER\Documents\advanced-database-portfolio\portfolio-4-nosql\mongodb\01-swiftbank-documents.js"
```

I change the `--file` path to each script in the following order while running the remaining files using the same executable and connection string:

1. I run `mongodb/01-swiftbank-documents.js` to recreate the demo database, add the JSON Schema validator and unique indexes, and insert three repeatable customer documents.
2. I run `mongodb/02-embedded-account-queries.js` to inspect embedded accounts and find customers with savings accounts.
3. I run `mongodb/03-account-type-aggregation.js` to count accounts and sum balances by type.
4. I run `mongodb/04-indexed-email-explain.js` to inspect the collection validator and indexes, then check `explain("executionStats")` for the unique-email lookup.
5. I run `mongodb/05-invalid-document-test.js` once to demonstrate that the validator rejects an unsupported account type. The expected validation error is intentional; this does not insert a document.
Model and results

The repeatable P1 seed data is matched by the three inserted customers, canonical emails, account numbers, account types, and balances. Instead of using JavaScript binary floating-point numbers, account balances use BSON `Decimal128`. A `recent_transactions` array with a validator limit of five items is also present in every customer document. I filled it in using the P1 seed rows pertaining to these three accounts. The transaction type, Decimal128 amount, date, status, direction and in the case of transfers, the counterparty account number are all recorded in the array. I include the seeded failed withdrawal with `status: "failed"`; this does not alter the balance, but it does record an unsuccessful attempt.

1,000.00 is moved in each direction by the two seeded transfers between SWB100002 and SWB100003. The embedded final balances of 80,000.00 and 30,000.00 still match the final P1 balances because their net effect is zero. SWB100001 is still valued at 50,000.00.

The validator checks the permitted account types, demands decimal balances and requires the important customer and account fields. `customer_id` and `email` are protected by unique indexes. The embedded account lookup, savings-account filter, account-type aggregate and indexed email query plan are displayed by the query scripts.

Evidence

The initial prototype, which employed numerical balances and in-place email updates, is documented in the earlier screenshots `evidence/01-...` through `evidence/07b-...`. They are kept as historical evidence and do not support the Decimal128 model or the updated validator.

Using the standalone Mongosh to recapture the updated evidence from my local MongoDB Community Server 9.0.4:

- `evidence/08-decimal128-customer-document.png`, `evidence/08-decimal128-customer-document-b.png` and `evidence/08-decimal128-customer-document-c.png` — all three customer documents with their embedded Decimal128 balances and recent transactions.
- `evidence/09-embedded-account-queries.png` and `evidence/09-embedded-account-queries-b.png` through `evidence/09-embedded-account-queries-d.png` — the embedded-account query output across four captures, including the recent transaction arrays. `evidence/09b-savings-account-query.png` retains the earlier savings-account query capture.
- `evidence/10-account-type-aggregation.png` — counts and Decimal128 totals by account type.
- `evidence/11-validator-and-unique-indexes.png` and `evidence/11-validator-and-unique-indexes-b.png` through `evidence/11-validator-and-unique-indexes-d.png` — both unique indexes and the full current collection validator, including the recent-transaction status and direction fields.
- `evidence/12-email-index-execution-stats.png` — the email lookup plan and execution statistics.
- `evidence/13-invalid-document-rejected.png` — actual validation error for the invalid account type.

Only my local results are recorded in these captures. Because there are three documents in this collection, the explain output shows the chosen index but is unable to demonstrate a significant improvement in performance.

Suitability and restrictions

A customer view that typically retrieves the customer and their accounts together is compatible with embedding account details. I would typically refer to the complete transaction history from a separate transaction collection rather than continuously expanding the customer document because a bank's transaction ledger can grow indefinitely. The matching P1 seed rows, including the unsuccessful withdrawal indicated by status, populate the five-item array, illustrating a bounded recent-history option.

For balances and money transfers, the PostgreSQL database is still the most reliable. If a dependable synchronization design isn't added, copying balances into MongoDB increases the possibility of stale or inconsistent values. This small customer-document example does not implement atomic debit, credit and ledger writes, which are necessary for money transfers.

To illustrate embedded customer-account reads, I selected a document model. A wide-column store is intended for large distributed write and analytical workloads, a graph model is helpful when relationship traversal is crucial, and a key-value store would fit direct key lookups or caching; none are required for this small coursework example.

References

- [MongoDB Manual: JSON Schema validation](https://www.mongodb.com/docs/manual/reference/operator/query/jsonschema/)
- [MongoDB Shell: BSON data types and Decimal128](https://www.mongodb.com/docs/mongodb-shell/reference/data-types/)
- [MongoDB Manual: unique indexes](https://www.mongodb.com/docs/manual/core/index-unique/)
- [MongoDB Manual: explain and execution statistics](https://www.mongodb.com/docs/manual/reference/command/explain/)
