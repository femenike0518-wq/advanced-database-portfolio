# Portfolio 5: Distributed and Cloud Database Exercise

## Purpose

This practical reviews replication-related settings on the local SwiftBank PostgreSQL server and discusses a possible primary-and-standby architecture.

## Tools

- PostgreSQL 18.6 and pgAdmin
- SQL inspection queries
- Architecture notes and screenshots

## Folder layout

- `sql/` — inspection queries (they do not configure replication)
- `evidence/` — screenshots
- `distributed-architecture-notes.txt` and `distributed-cloud-notes.txt` — proposal, status and design considerations

## Implementation and findings

The SQL inspects the PostgreSQL version, SwiftBank tables, recovery status, `pg_stat_replication`, and the `wal_level`, `max_wal_senders` and `hot_standby` settings. The recorded settings were `wal_level = replica`, `max_wal_senders = 10` and `hot_standby = on`. The server reported that it was not in recovery, and `pg_stat_replication` showed no connected standby.

The notes propose a primary server streaming WAL to a separate standby and discuss replication lag, consistency, availability, sharding and recovery.

## Evidence

- `sql/01-inspect-replication.sql` — inspection queries; it does not configure replication.
- `distributed-architecture-notes.txt` and `distributed-cloud-notes.txt` — proposal, status and design considerations.
- `evidence/05-replication-status.png`, `evidence/06-distributed-architecture-notes.png` and `evidence/07-replication-configuration-settings.png` — replication status, proposed design and settings.
- `evidence/01-distributed-cloud-notes.png`, `evidence/02-postgresql-version-and-database.png`, `evidence/03-swiftbank-table-list.png` and `evidence/04-postgresql-replication-role.png` — local PostgreSQL version, database and SwiftBank tables.

## Limitation

This work documents a settings review and architecture proposal only. A separate standby, active streaming replication and failover were not configured or demonstrated.
