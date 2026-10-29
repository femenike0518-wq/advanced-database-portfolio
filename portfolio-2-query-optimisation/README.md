# Portfolio 2: Query Processing and Optimisation

## Purpose

This practical uses PostgreSQL query plans to examine account-balance queries and test whether an index on `accounts.balance` improves the observed execution.

## Tools

- PostgreSQL and pgAdmin
- SQL `EXPLAIN ANALYZE`
- `pg_indexes` to inspect the created indexes

## Folder layout

- `sql/` — scripts in run order for the recorded small-table experiment
- `sql/superseded/` — earlier one-statement files that were absorbed into the canonical script
- `evidence/` — plan and result screenshots
- `performance-observations.txt` — timings and interpretation

## Canonical scripts versus superseded files

The script I actually ran as a sequence is `sql/01-small-table-experiment.sql` (previously `portfolio-2-query-optimisation1.sql`). It contains the baseline plan, index creation, the after-index plan, the balance-only filter, and the index listing.

These files are kept only so the earlier filenames remain in git history:

- `sql/superseded/explain-analyze.sql` — the join query used for `EXPLAIN ANALYZE`
- `sql/superseded/join-query-only.sql` — the same join without the surrounding experiment comments
- `sql/superseded/create-index.sql` — the `CREATE INDEX` statement already included in the canonical script

`sql/02-account-balance-summary.sql` is the aggregate report by account type.

## Implementation

The baseline query was measured with `EXPLAIN ANALYZE`; an index named `idx_accounts_balance` was then created and the query was run again. A separate balance filter and an aggregate query by account type were also examined.

## Results

The recorded baseline execution time was approximately **0.108 ms**; after index creation it was approximately **0.133 ms**. PostgreSQL chose sequential scans for the tested plans, including the balance filter, and did not use the new balance index. The index was present in the index listing. The account summary reported one current account with a balance of 80,000 and two savings accounts totalling 80,000, based on the sample data.

## Performance Analysis

The query took approximately 0.108 ms before the index was created and 0.133 ms after the index was created. In this test, the indexed query was slightly slower rather than faster.

The execution plans showed that PostgreSQL continued to use sequential scans instead of the new balance index. This is reasonable for the small sample dataset because scanning a small table can cost less than using an index. The timing difference is very small, so it should not be treated as proof that indexing makes queries slower in general.

The index was created successfully and appeared in the index listing, but it did not improve the measured execution time in this experiment. A larger dataset and repeated measurements would be needed to evaluate its performance more reliably.

## Evidence

- `sql/01-small-table-experiment.sql` and `sql/02-account-balance-summary.sql` — query and index statements used in this practical.
- `evidence/01-baseline-execution-plan.png`, `evidence/02-indexed-execution-plan.png` and `evidence/03-balance-filter-plan.png` — plan screenshots.
- `evidence/04-accounts-index-list.png` — index verification.
- `evidence/05-account-balance-summary.png` — aggregate query output.
- `performance-observations.txt` — timings and interpretation.

## Limitation

The sample table is very small. These measurements are a practical demonstration, not a general benchmark; the difference is too small to establish that either plan will perform better on a larger dataset. Index usefulness depends on table size, data distribution and query conditions.

## Conclusion

This practical demonstrated how to inspect PostgreSQL query execution plans using `EXPLAIN ANALYZE`, create an index, and compare query performance before and after indexing. The results showed that adding an index does not automatically improve performance. Query plans, table size, and measured execution time must be considered when deciding whether an index is useful.
