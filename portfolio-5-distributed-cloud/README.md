# Portfolio 5: Distributed and Cloud Database Exercise

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

1. Run `sql/01-inspect-replication.sql` in pgAdmin on the primary to review version, tables and settings.
2. Run `sql/02-create-replication-role.sql` on the primary. Set the role password locally in pgAdmin; do not place it in a script or this repository. Confirm the primary's `pg_hba.conf` allows the replication connection from `127.0.0.1/32` and reload PostgreSQL if you change it.
3. In PowerShell, use the installed PostgreSQL 18 tools to take a base backup. Enter the replication-role password at the prompt:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\pg_basebackup.exe" -h 127.0.0.1 -p 5432 -U swiftbank_repl -D "C:\Users\USER\Documents\swiftbank-standby" -Fp -Xs -P -R -W
   ```

   The standby directory is outside this repository. The generated standby connection configuration can contain the replication password; never copy it into Git or screenshots.
4. Start the standby on port 5433:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe" -D "C:\Users\USER\Documents\swiftbank-standby" -o "-p 5433 -h 127.0.0.1 -c logging_collector=off" -l "C:\Users\USER\Documents\swiftbank-standby-startup.log" start
   & "C:\Program Files\PostgreSQL\18\bin\pg_isready.exe" -h 127.0.0.1 -p 5433
   ```

   `pg_isready` should report `accepting connections`. In pgAdmin, register a separate server named `SwiftBank Standby` with host `127.0.0.1`, port `5433`, database `swiftbank`, and your local PostgreSQL login.
5. Run the query in `sql/01-inspect-replication.sql` for `pg_stat_replication` on the primary and confirm `streaming`.
6. Run `sql/03-setup-replication-demo.sql` on the primary. Run `sql/04-verify-standby.sql` on the standby and confirm port `5433`, `is_standby = true`, and the replicated marker row.
7. Run `sql/05-test-standby-write-rejection.sql` only on the standby. The expected result is a read-only transaction error with SQLSTATE `25006`.

The scripts cover the SQL steps; PowerShell setup is a one-time local lab procedure. The backup command's `-R` writes connection information to the external standby directory, so that directory must remain private and untracked.

## Evidence

- `evidence/07-replication-configuration-settings.png` — primary replication settings.
- `evidence/08-replication-role-created.png` — limited replication role attributes.
- `evidence/09-pg-basebackup-complete.png` and `evidence/10-standby-started.png` — completed base backup and standby startup.
- `evidence/10-primary-streaming-status.png` — `pg_stat_replication` showed the standby streaming asynchronously.
- `evidence/11-primary-demo-write.png`, `evidence/12-standby-identity-check.png`, `evidence/12-standby-replicated-row.png` and `evidence/13-standby-replicated-rows.png` — primary marker write, standby identity and replicated rows (the two-row capture predates cleanup).
- `evidence/14-standby-write-rejected.png` — standby rejected the write with SQLSTATE `25006`.
- `evidence/15-standby-cleanup-verified.png` — primary cleanup was reflected on the standby.

## Limitations

This is a single-machine, local asynchronous replication demonstration. It does not test network failure, sustained replication lag, automatic or manual failover, synchronous replication, backups, security hardening, or production availability. The standby can lag behind the primary, so it should not be treated as an authoritative source for current banking balances. The primary remains the authoritative database for writes. The earlier settings-only inspection is retained as evidence of the initial state before the standby was connected.
