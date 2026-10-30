-- MIT 8103 Portfolio 5: create an isolated replication demonstration row.
-- Run on the primary (port 5432) after the physical standby is configured.
-- This creates only a separate demo schema; it does not touch SwiftBank tables.
CREATE SCHEMA IF NOT EXISTS p5_replication_demo;

CREATE TABLE IF NOT EXISTS p5_replication_demo.replication_check (
    marker_id integer PRIMARY KEY,
    note text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO p5_replication_demo.replication_check (marker_id, note)
VALUES (1, 'Written on primary')
ON CONFLICT (marker_id) DO UPDATE
SET note = EXCLUDED.note,
    created_at = now();

SELECT *
FROM p5_replication_demo.replication_check
ORDER BY marker_id;
