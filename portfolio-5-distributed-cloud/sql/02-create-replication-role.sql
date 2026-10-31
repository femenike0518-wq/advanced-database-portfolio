-- MIT 8103 Portfolio 5: create the local streaming replication login.
-- Run in pgAdmin's Query Tool connected to the existing swiftbank primary.
-- Re-runnable: preserves an existing password while ensuring only the required
-- login and replication attributes are present.
-- The script does not change SwiftBank tables or balances.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'swiftbank_repl'
    ) THEN
        EXECUTE 'ALTER ROLE swiftbank_repl
                 WITH LOGIN REPLICATION NOSUPERUSER NOCREATEDB
                 NOCREATEROLE NOINHERIT';
    ELSE
        EXECUTE 'CREATE ROLE swiftbank_repl
                 WITH LOGIN REPLICATION NOSUPERUSER NOCREATEDB
                 NOCREATEROLE NOINHERIT';
    END IF;
END
$$;

-- Verify the role attributes without displaying a password.
SELECT rolname,
       rolcanlogin,
       rolreplication,
       rolsuper,
       rolcreatedb,
       rolcreaterole,
       rolinherit
FROM pg_roles
WHERE rolname = 'swiftbank_repl';
