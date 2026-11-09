Portfolio 5: Distributed and Cloud Database Exercise

> AI-use declaration: See the [root README](../README.md#ai-use-declaration).

Case study and purpose

I examined PostgreSQL replication settings using the hypothetical SwiftBank banking system before establishing a different local physical standby. My current PostgreSQL 18.6 server on port 5432 is still the main. The standby does not replace or alter the primary data directory; instead, it uses a different data directory and port 5433.

Tools and environment

- PostgreSQL 18.6 and pgAdmin on Windows
- PostgreSQL's `pg_basebackup` was used to create a local streaming standby, which was initiated with `pg_ctl`.
- To confirm replication, use `pg_stat_replication`, `pg_is_in_recovery()` and an isolated marker table.

Implementation and results

I confirmed `wal_level = replica`, `max_wal_senders = 10` and `hot_standby = on` on the primary. I created the limited `swiftbank_repl` login, used `pg_basebackup` to copy the primary into a separate standby directory, and started the standby on port 5433. The primary's `pg_stat_replication` showed one connected client in `streaming` state with `sync_state = async`.

I used `p5_replication_demo.replication_check` to prevent altering SwiftBank's banking tables. The standby displayed a marker row that was written on the primary. The error message `cannot execute INSERT in a read-only transaction` (SQLSTATE `25006`) was used to reject a write attempt on the standby. I verified that the deletion also reached the standby after an extra marker row was inadvertently removed from the primary. These tests show local asynchronous streaming replication, but they don't show production availability or failover.

Run order

1. I execute `sql/01-inspect-replication.sql` in pgAdmin on the primary to review the version, tables and settings.
2. On the primary, I execute `sql/02-create-replication-role.sql`. I keep the role password out of scripts and this repository and set it locally in pgAdmin. I verify that the replication connection from `127.0.0.1/32` is permitted by the primary's `pg_hba.conf` and reload PostgreSQL if I make any changes.
3. I create a base backup in PowerShell using the installed PostgreSQL 18 tools. At the prompt, I input the replication-role password:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\pg_basebackup.exe" -h 127.0.0.1 -p 5432 -U swiftbank_repl -D "C:\Users\USER\Documents\swiftbank-standby" -Fp -Xs -P -R -W
   ```

   I keep the standby directory outside this repository. The generated standby connection configuration can contain the replication password, so I keep it out of Git and screenshots.
4. I start the standby on port 5433:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe" -D "C:\Users\USER\Documents\swiftbank-standby" -o "-p 5433 -h 127.0.0.1 -c logging_collector=off" -l "C:\Users\USER\Documents\swiftbank-standby-startup.log" start
   & "C:\Program Files\PostgreSQL\18\bin\pg_isready.exe" -h 127.0.0.1 -p 5433
   ```

   `pg_isready` reports `accepting connections` in my setup. In pgAdmin, I register a separate server named `SwiftBank Standby` with host `127.0.0.1`, port `5433`, database `swiftbank`, and my local PostgreSQL login.
5. I run the query in `sql/01-inspect-replication.sql` for `pg_stat_replication` on the primary and confirm `streaming`.
6. I run `sql/03-setup-replication-demo.sql` on the primary. I run `sql/04-verify-standby.sql` on the standby and confirm port `5433`, `is_standby = true`, and the replicated marker row.
7. I run `sql/05-test-standby-write-rejection.sql` on the standby. The expected result is a read-only transaction error with SQLSTATE `25006`.

My SQL steps are covered by the scripts; I use PowerShell setup as a one-time local lab procedure. I keep the external standby directory private and untracked because the backup command's `-R` writes connection information to it.

Evidence

- `evidence/07-replication-configuration-settings.png` — primary replication settings.
- `evidence/08-replication-role-created.png` — limited replication role attributes.
- `evidence/09-pg-basebackup-complete.png`, `evidence/10a-standby-started.png` and `evidence/10b-primary-streaming-status.png` — completed base backup, standby startup and asynchronous streaming status, in setup order.
- `evidence/11-primary-demo-write.png`, `evidence/12a-standby-identity-check.png`, `evidence/12b-standby-replicated-row.png` and `evidence/13-standby-replicated-rows.png` — primary marker write, standby identity and replicated rows (the two-row capture predates cleanup).
- `evidence/14-standby-write-rejected.png` — standby rejected the write with SQLSTATE `25006`.
- `evidence/15-standby-cleanup-verified.png` — primary cleanup was reflected on the standby.

Restrictions

On a single machine, I demonstrated local asynchronous replication. Network failure, persistent replication lag, automatic or manual failover, synchronous replication, backups, security hardening and production availability were not tested by me. I do not consider the standby to be a reliable source for current banking balances because it may lag behind the primary. For writers, the primary continues to be authoritative. Before connecting the standby, I kept the previous settings-only inspection as proof of the initial state.

Distributed design discussion

I've implemented a standby for local asynchronous streaming. When using asynchronous replication, a standby read may display an older balance because the primary can acknowledge a balance update before its WAL reaches the standby. When a necessary standby is unable to respond, synchronous replication can increase durability for acknowledged commits at the expense of latency and write availability. In order to prevent customers and transfer logic from acting on stale replica values, I would read current balances from the primary.

In order to keep each customer's accounts together, I could shard by `customer_id` if SwiftBank required it. In order to coordinate account updates and the ledger record atomically, a transfer between customers assigned to different shards would require distributed transaction handling. Inaccurate balances would result from a partial debit or credit.

I would give a bank's balance-changing operations top priority while clearly planning availability and recovery. In terms of CAP, a network partition forces a choice between maintaining a single consistent balance state and serving writes on both sides; under PACELC, stronger coordination can increase latency even without a partition. Self-managed PostgreSQL on cloud virtual machines or containers, or managed PostgreSQL with automated backups and managed replicas, could be used in a cloud deployment. Before choosing a service, I would consider access controls, recovery goals, data location, monitoring, and cost. I did not put these sharding, consistency, and cloud options into practice; they are merely discussions. The local asynchronous standby mentioned above is the replication setup I have put in place.

For the fuller discussion, see my [distributed and cloud notes](distributed-cloud-notes.txt) and [distributed architecture notes](distributed-architecture-notes.txt).
