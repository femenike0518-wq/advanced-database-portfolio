# Portfolio 3: Transactions and Concurrency

## Purpose

This practical demonstrates transaction control and read visibility across two PostgreSQL sessions using the SwiftBank sample database.

## Tools

- PostgreSQL and pgAdmin
- Two query sessions for the concurrency demonstration
- SQL transaction commands and screenshots

## Folder layout

- `sql/` — transaction demonstration script
- `evidence/` — screenshots
- `transaction-concurrency-notes.txt` — recorded isolation and rollback observations

## Implementation and observations

The SQL examples use `BEGIN`, `COMMIT` and `ROLLBACK`. For the two-session test, the isolation level was `READ COMMITTED`. Session A changed account 1's balance by 100 but left the transaction uncommitted. While that change was pending, Session B continued to read the prior committed balance of 50,000. Session A then rolled back, and the balance remained 50,000.

A separate commit example updated a customer record. The notes and screenshots also document restoring the original email value after that demonstration.

## How to follow the concurrency evidence

Use two sessions connected to the SwiftBank database. Keep Session A's transaction open while running the read in Session B, then return to Session A and issue `ROLLBACK`. This ordering demonstrates that Session B does not see Session A's uncommitted change under the recorded isolation level.

## Files and evidence

- `sql/01-transactions-concurrency.sql` — transaction examples and two-session steps.
- `transaction-concurrency-notes.txt` — recorded isolation and rollback observations.
- `evidence/01-rollback-demonstration.png`, `evidence/01b-rollback-demonstration.png`, `evidence/02-commit-demonstration.png`, `evidence/03-transaction-isolation.png`, `evidence/04-session-b-uncommitted-read.png`, `evidence/05-rollback-after-concurrency.png`, `evidence/06-visible-commit-demonstration.png`, `evidence/07-original-email-restored.png` — rollback, commit, Session B's read and restoration of original values.

## Scope

The results document a small demonstration in two local sessions; they do not represent a load or stress test.
