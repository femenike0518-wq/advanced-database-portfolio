# Portfolio 5: Distributed and Cloud Database Exercise

> AI-use declaration: See the [root README](../README.md#ai-use-declaration).

## Case study and purpose

I used the fictional SwiftBank banking system to inspect PostgreSQL replication settings and then set up a separate local physical standby. The primary remains my existing PostgreSQL 18.6 server on port 5432. The standby uses a separate data directory and port 5433; it does not replace or modify the primary data directory.

## Tools and environment

- PostgreSQL 18.6 and pgAdmin on Windows
- A local streaming standby created with PostgreSQL `pg_basebackup` and started with `pg_ctl`
- `pg_stat_replication`, `pg_is_in_recovery()` and an isolated marker table to verify replication

## Implementation and results

I verified `wal_level = replica`, `max_wal_senders = 10` and `hot_standby = on` on the primary. I created the limited `swiftbank_repl` login, used `pg_basebackup` to copy the primary into a separate standby directory, and started the standby on port 5433. The primary's `pg_stat_replication` showed one connected client in `streaming` state with `sync_state = async`.

To avoid changing SwiftBank's banking tables, I used `p5_replication_demo.replication_check`. A marker row written on the primary appeared on the standby. A write attempt on the standby was rejected with `cannot execute INSERT in a read-only transaction` (SQLSTATE `25006`). After an accidental extra marker row was removed on the primary, I confirmed the deletion also reached the standby. These checks demonstrate local asynchronous streaming replication; they do not demonstrate failover or production availability.

## Run order

1. I run `sql/01-inspect-replication.sql` in pgAdmin on the primary to review the version, tables and settings.
2. I run `sql/02-create-replication-role.sql` on the primary. I set the role password locally in pgAdmin and keep it out of scripts and this repository. I confirm the primary's `pg_hba.conf` allows the replication connection from `127.0.0.1/32` and reload PostgreSQL if I change it.
3. In PowerShell, I use the installed PostgreSQL 18 tools to take a base backup. I enter the replication-role password at the prompt:

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

The scripts cover my SQL steps; I use PowerShell setup as a one-time local lab procedure. The backup command's `-R` writes connection information to the external standby directory, so I keep that directory private and untracked.

## Evidence

- `evidence/07-replication-configuration-settings.png` — primary replication settings.
- `evidence/08-replication-role-created.png` — limited replication role attributes.
- `evidence/09-pg-basebackup-complete.png`, `evidence/10a-standby-started.png` and `evidence/10b-primary-streaming-status.png` — completed base backup, standby startup and asynchronous streaming status, in setup order.
- `evidence/11-primary-demo-write.png`, `evidence/12a-standby-identity-check.png`, `evidence/12b-standby-replicated-row.png` and `evidence/13-standby-replicated-rows.png` — primary marker write, standby identity and replicated rows (the two-row capture predates cleanup).
- `evidence/14-standby-write-rejected.png` — standby rejected the write with SQLSTATE `25006`.
- `evidence/15-standby-cleanup-verified.png` — primary cleanup was reflected on the standby.

## Limitations

I demonstrated local asynchronous replication on a single machine. I did not test network failure, sustained replication lag, automatic or manual failover, synchronous replication, backups, security hardening, or production availability. The standby can lag behind the primary, so I do not treat it as an authoritative source for current banking balances. The primary remains authoritative for writes. I retained the earlier settings-only inspection as evidence of the initial state before I connected the standby.

## Distributed design discussion

My implementation is a local asynchronous streaming standby. With asynchronous replication, the primary can acknowledge a balance update before its WAL reaches the standby; during that lag, a standby read may show an older balance. Synchronous replication waits for a standby acknowledgement, which can improve durability for acknowledged commits at the cost of latency and write availability when a required standby cannot respond. I would read current balances from the primary so customers and transfer logic do not act on stale replica values.

If SwiftBank needed sharding, I could shard by `customer_id` so each customer's accounts are kept together. A transfer between customers assigned to different shards would need distributed transaction handling to coordinate both account updates and the ledger record atomically. A partial debit or credit would leave incorrect balances.

For a bank, I would prioritize consistency for balance-changing operations, while planning availability and recovery explicitly. In CAP terms, a network partition forces a choice between serving writes on both sides and preserving a single consistent balance state; under PACELC, even without a partition, stronger coordination can add latency. A cloud deployment could use managed PostgreSQL with automated backups and managed replicas, or self-managed PostgreSQL on cloud virtual machines or containers. I would evaluate access controls, recovery objectives, data location, monitoring and cost before selecting a service. These sharding, consistency and cloud options are discussion only; I did not implement them. My implemented replication setup is the local asynchronous standby described above.

For the fuller discussion, see my [distributed and cloud notes](distributed-cloud-notes.txt) and [distributed architecture notes](distributed-architecture-notes.txt).
