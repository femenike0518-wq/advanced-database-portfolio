-- MIT 8103 Portfolio 5
-- SwiftBank Distributed and Cloud Database Exercise
-- Purpose: inspect the existing database and prepare evidence for a
-- primary-and-replica architecture discussion.

-- 1. Confirm the PostgreSQL version and current database.
SELECT version() AS postgresql_version,
       current_database() AS database_name;

-- 2. List the SwiftBank tables.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 3. Inspect the customer and account records.
SELECT c.customer_id,
       c.full_name,
       c.email,
       a.account_number,
       a.account_type,
       a.balance
FROM customers AS c
JOIN accounts AS a
  ON c.customer_id = a.customer_id
ORDER BY c.customer_id;

-- 4. Check the current server's replication role and status.
-- This is an inspection query; it does not configure replication.
SELECT pg_is_in_recovery() AS is_standby_server;

SELECT * FROM pg_stat_replication;


-- 5. Inspect replication-related server settings.
SELECT name, setting
FROM pg_settings
WHERE name IN (
    'wal_level',
    'max_wal_senders',
    'hot_standby'
)
ORDER BY name;