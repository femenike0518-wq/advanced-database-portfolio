-- MIT 8103 Portfolio 5: verify the standby and replicated demo data.
-- Run in pgAdmin connected specifically to SwiftBank Standby (port 5433).
SELECT inet_server_port() AS port,
       pg_is_in_recovery() AS is_standby;

SELECT *
FROM p5_replication_demo.replication_check
ORDER BY marker_id;
