# Portfolio 2: Query Processing and Optimisation

## Purpose

This practical uses PostgreSQL query plans to examine account-balance queries and test whether an index on `accounts.balance` improves the observed execution.

## Tools

- PostgreSQL and pgAdmin
- SQL `EXPLAIN ANALYZE`
- `pg_indexes` to inspect the created indexes

## Implementation

The baseline query was measured with `EXPLAIN ANALYZE`; an index named `idx_accounts_balance` was then created and the query was run again. A separate balance filter and an aggregate query by account type were also examined.

## Results

The recorded baseline execution time was approximately **0.108 ms**; after index creation it was approximately **0.133 ms**. PostgreSQL chose sequential scans for the tested plans, including the balance filter, and did not use the new balance index. The index was present in the index listing. The account summary reported one current account with a balance of 80,000 and two savings accounts totalling 80,000, based on the sample data.

## Evidence

- `EXPLAIN ANALYZE.sql`, `CREATE INDEX.sql` and the portfolio SQL files — query and index statements.
- `01-baseline-execution-plan.png.png`, `02-indexed-execution-plan.png.png` and `03-balance-filter-plan.png.png` — plan screenshots.
- `04-accounts-index-list.png.png` — index verification.
- `05-account-balance-summary.sql` and `05-account-balance-summary.png.png` — aggregate query and output.
- `performance-observations.txt` — timings and interpretation.

## Limitation

The sample table is very small. These measurements are a practical demonstration, not a general benchmark; the difference is too small to establish that either plan will perform better on a larger dataset. Index usefulness depends on table size, data distribution and query conditions.
