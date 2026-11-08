# Portfolio 3: Transactions and Concurrency

> AI-use declaration: See the [root README](../README.md#ai-use-declaration).

Purpose

I demonstrated atomic funds transfers, rollback, transaction isolation, a lost update and concurrency control using a small SwiftBank test schema. The demo data is separate from the `public` tables in the portfolio and is fictitious.

Environment

- PostgreSQL 18.6 and pgAdmin 4
- Two sessions of the pgAdmin Query Tool were used to demonstrate concurrency 
- Dedicated schema: `p3_demo`

Safety and reset

All existing scripts use `p3_demo` to qualify their objects. Only that schema is dropped and recreated by the setup script. Neither the P1 sample data nor `public` are altered. For this exercise, I set aside `p3_demo`.

To return to the same initial state, I execute `sql/01-setup-demo-schema.sql` prior to a new run. I commit or roll back the open transactions before rerunning it while a demonstration transaction is open. Three fictitious clients and three accounts are created by the setup: account 1 begins at 5,000.00, account 2 at 2,500.00, and account 3 at 100.00 for the example of insufficient funds.

Run order

1. To reset just `p3_demo` and display the initial accounts, I execute `sql/01-setup-demo-schema.sql`.
2. To move 750.00 from account 1 to account 2, I execute `sql/02-committed-funds-transfer.sql`; the ledger row, debit and credit are all committed simultaneously. When gathering evidence, I run the queries for the before and after results independently.
3. The debit statement in `sql/03-insufficient-funds-rollback.sql` is executed independently. The attempted `-650.00` balance is rejected by the balance check; I run `ROLLBACK` independently to confirm that account 3 stays at 100.00, account 2 stays at 3,250.00 and the failed transfer has no ledger row.
4. After the committed transfer, I proceed in the order specified by the SESSION A and SESSION B blocks in `sql/04-read-committed-two-sessions.sql`. Session B at READ COMMITTED sees the committed 3,250.00; Session A adds 100.00 to account 2 but does not commit it. I confirm that the balance is still 3,250.00 by rolling back A.
5. In two sessions following the transfer, I follow each highlighted block in `sql/05-lost-update-two-sessions.sql`. Account 1 was read at 4,250.00 in both sessions. After withdrawing 150.00, Session B commits a stale calculation of 4,100.00; for withdrawing $100.00, Session A commits a stale calculation of 4,150.00. The balance would be 4,000.00 if both withdrawals were applied; the final 4,150.00 is a lost update.
6. After the lost-update test, I follow the blocks in `sql/06-guarded-concurrent-withdrawals.sql` in two sessions. The guarded 100.00 withdrawal made by Session A reduces the balance from 4,150.00 to 4,050.00 while maintaining a row lock. After A commits, B applies to the new balance, while Session B's guarded 150.00 withdrawal waits. 3,900.00 is the final balance.

I follow the comments for files 03–06, which include steps that call for two distinct Query Tool sessions, pauses while a transaction is open, and a visible constraint error. I don't use a single Query Tool session to run a whole file.

Expected results

| Demonstration | Expected result |
| --- | --- |
| Committed transfer | Account 1: 4,250.00; account 2: 3,250.00; one completed transfer ledger row |
| Insufficient funds | Check constraint rejects the attempted -650.00 balance; account 3 remains 100.00; account 2 remains 3,250.00; no failed transfer ledger row |
| READ COMMITTED visibility | Session A sees 3,350.00 in its transaction; Session B sees committed 3,250.00; rollback leaves 3,250.00 |
| Unguarded read-then-write | Final 4,150.00 instead of the expected 4,000.00, showing Session B's 150.00 withdrawal was overwritten |
| Guarded atomic updates | Final 3,900.00 after both withdrawals are applied in sequence |

Evidence

These are real pgAdmin screenshots that were stored under `evidence/`:

- [08-isolated-demo-accounts.png](evidence/08-isolated-demo-accounts.png)
- [09-committed-transfer-balances.png](evidence/09-committed-transfer-balances.png) (account balances and transfer row)
- [10-insufficient-funds-error.png](evidence/10-insufficient-funds-error.png)
- [11-insufficient-funds-rollback.png](evidence/11-insufficient-funds-rollback.png)
- [12-rollback-state-verified.png](evidence/12-rollback-state-verified.png)
- [13-read-committed-session-a-uncommitted.png](evidence/13-read-committed-session-a-uncommitted.png)
- [14-read-committed-session-b-cannot-see-uncommitted.png](evidence/14-read-committed-session-b-cannot-see-uncommitted.png)
- [15-read-committed-session-a-rollback.png](evidence/15-read-committed-session-a-rollback.png)
- [16-read-committed-after-rollback.png](evidence/16-read-committed-after-rollback.png)
- [17-lost-update-session-a-reads-balance.png](evidence/17-lost-update-session-a-reads-balance.png)
- [18-lost-update-session-b-reads-same-balance.png](evidence/18-lost-update-session-b-reads-same-balance.png)
- [19-lost-update-session-b-writes-stale-value.png](evidence/19-lost-update-session-b-writes-stale-value.png)
- [20-lost-update-session-a-overwrites-b.png](evidence/20-lost-update-session-a-overwrites-b.png) (successful commit message, paired with the final balance below)
- [21-lost-update-final-state.png](evidence/21-lost-update-final-state.png)
- [22-guarded-session-a-withdrawal.png](evidence/22-guarded-session-a-withdrawal.png)
- [23-guarded-session-b-withdrawal.png](evidence/23-guarded-session-b-withdrawal.png)
- [24-guarded-final-state.png](evidence/24-guarded-final-state.png)

The actual PostgreSQL 18.6 results are displayed in these screenshots. Account 1 was 4,250.00 after the transfer; the intentionally unguarded concurrent update left it at 4,150.00 instead of 4,000.00; the guarded withdrawals then both applied and left it at 3,900.00. The final-state value in `21-lost-update-final-state.png` is matched with the commit message in the `20-...` screenshot.

The actual pgAdmin output is captured in the screenshots. The separate results for two-session demonstrations display the final balance as well as the read or update from each session.

Earlier evidence and restrictions

An earlier run against the shared `public` sample tables is documented in the current screenshots `01-rollback-demonstration.png` through `07-original-email-restored.png`. The archived `superseded/public-schema-transactions-concurrency.sql` is not run in the current workflow; I only keep them as historical evidence.

These are not load tests; rather, they are brief local demonstrations. To illustrate the problem, the lost-update example purposefully employs a stale value. The control shown here is the guarded `UPDATE ... WHERE balance >= amount`; beyond this coursework exercise, a production banking system would require more extensive validation, authorization, auditing and operational controls.
