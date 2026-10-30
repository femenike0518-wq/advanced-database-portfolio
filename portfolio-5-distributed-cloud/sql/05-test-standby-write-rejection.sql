-- MIT 8103 Portfolio 5: demonstrate that the standby rejects writes.
-- Run only on the standby (port 5433). On the primary, the guard inserts 0 rows.
-- On a hot standby, PostgreSQL rejects the INSERT with SQLSTATE 25006.
WITH standby_guard AS (
    SELECT pg_is_in_recovery() AS is_standby
)
INSERT INTO p5_replication_demo.replication_check (marker_id, note)
SELECT 3, 'Standby write rejection test'
FROM standby_guard
WHERE is_standby;
