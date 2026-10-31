# Portfolio 3: Transactions and Concurrency

## Purpose

I use a small SwiftBank test schema to demonstrate atomic funds transfers, rollback, transaction isolation, a lost update and a concurrency control. The demo data is fictional and isolated from the portfolio's `public` tables.

## Environment

- PostgreSQL 18.6 and pgAdmin 4
- Two pgAdmin Query Tool sessions for the concurrency demonstrations
- Dedicated schema: `p3_demo`

## Safety and reset

All current scripts qualify their objects with `p3_demo`. The setup script drops and recreates only that schema. It does not change `public` or the P1 sample data. Do not put unrelated objects in `p3_demo`.

Run `sql/01-setup-demo-schema.sql` before a fresh run to restore the same starting state. Do not rerun it while a demonstration transaction is open; first commit or roll back the open transactions. The setup creates three fictional customers and three accounts: account 1 starts at 5,000.00, account 2 at 2,500.00, and account 3 at 100.00 for the insufficient-funds example.

## Run order

1. `sql/01-setup-demo-schema.sql` — reset only `p3_demo` and show the starting accounts.
2. `sql/02-committed-funds-transfer.sql` — transfer 750.00 from account 1 to account 2; debit, credit and ledger row are committed together. Run the before and after result queries separately when capturing evidence.
3. `sql/03-insufficient-funds-rollback.sql` — run the debit statement by itself. The balance check rejects the attempted `-650.00` balance; run `ROLLBACK` separately, then verify account 3 remains at 100.00, account 2 remains at 3,250.00, and the failed transfer has no ledger row.
4. `sql/04-read-committed-two-sessions.sql` — follow the SESSION A and SESSION B blocks in order after the committed transfer. Session A adds 100.00 to account 2 but leaves it uncommitted; Session B at READ COMMITTED sees the committed 3,250.00. Roll back A and verify the balance remains 3,250.00.
5. `sql/05-lost-update-two-sessions.sql` — follow each marked block in two sessions after the transfer. Both sessions read account 1 at 4,250.00. Session B commits a stale calculation of 4,100.00 after its 150.00 withdrawal; Session A then commits its stale calculation of 4,150.00 for its 100.00 withdrawal. The final 4,150.00 is a lost update; if both withdrawals were applied, the balance would be 4,000.00.
6. `sql/06-guarded-concurrent-withdrawals.sql` — follow the blocks in two sessions after the lost-update test. Starting at 4,150.00, Session A's guarded 100.00 withdrawal changes the balance to 4,050.00 and holds a row lock. Session B's guarded 150.00 withdrawal waits; after A commits, B applies to the new balance. The final balance is 3,900.00.

For files 03–06, follow the comments in order; they include steps that require a visible constraint error, two separate Query Tool sessions, and pauses while a transaction remains open. Do not run the entire file in one Query Tool session.

## Expected results

| Demonstration | Expected result |
| --- | --- |
| Committed transfer | Account 1: 4,250.00; account 2: 3,250.00; one completed transfer ledger row |
| Insufficient funds | Check constraint rejects the attempted -650.00 balance; account 3 remains 100.00; account 2 remains 3,250.00; no failed transfer ledger row |
| READ COMMITTED visibility | Session A sees 3,350.00 in its transaction; Session B sees committed 3,250.00; rollback leaves 3,250.00 |
| Unguarded read-then-write | Final 4,150.00 instead of the expected 4,000.00, showing Session B's 150.00 withdrawal was overwritten |
| Guarded atomic updates | Final 3,900.00 after both withdrawals are applied in sequence |

## Evidence

The following are actual pgAdmin screenshots saved under `evidence/`:

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

These screenshots show the actual PostgreSQL 18.6 results. Account 1 was 4,250.00 after the transfer; the intentionally unguarded concurrent update left it at 4,150.00 instead of 4,000.00; the guarded withdrawals then both applied and left it at 3,900.00. The commit message in the `20-...` screenshot is paired with the final-state value in `21-lost-update-final-state.png`.

The screenshots document the actual pgAdmin output. For two-session demonstrations, the separate results show each session's read or update and the final balance.

## Earlier evidence and limitations

The existing screenshots `01-rollback-demonstration.png` through `07-original-email-restored.png` document an earlier run against the shared `public` sample tables. They are retained as historical evidence only; the archived `superseded/public-schema-transactions-concurrency.sql` is not the current script and must not be run.

These are small local demonstrations, not a load test. The lost-update example intentionally uses a stale value to show the issue. The guarded `UPDATE ... WHERE balance >= amount` is the control demonstrated here; a production banking system would also need broader validation, authorization, auditing and operational controls beyond this coursework exercise.
