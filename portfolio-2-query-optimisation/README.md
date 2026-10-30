# Portfolio 2: Query Processing and Optimisation

## Purpose

I used PostgreSQL query plans to examine balance and transaction queries for the SwiftBank case study. I kept the original three-account result as a small-table example and added a larger, isolated synthetic benchmark so I could compare plans on more rows without changing the SwiftBank sample data.

## Tools and environment

- PostgreSQL 18.6 and pgAdmin 4
- SQL `EXPLAIN (ANALYZE, BUFFERS)`
- Synthetic benchmark schema: `p2_benchmark`

## Run order

Run the original small-table exercise in the SwiftBank database:

1. `sql/01-small-table-experiment.sql` drops and recreates only `public.idx_accounts_balance`; it does not alter the sample rows. Run the script after Portfolio 1 has created `public.customers` and `public.accounts`.
2. `sql/02-account-balance-summary.sql` reports the sample balances by account type.

Run the larger benchmark in a database where your role can create schemas:

3. `sql/03-build-benchmark-schema.sql` recreates only the `p2_benchmark` schema and loads deterministic fictional rows. **It drops any existing `p2_benchmark` schema**, so use that schema only for this exercise. It does not change `public` or other schemas.
4. `sql/04a-baseline-plans-and-measurements.sql` records baseline plans and measurements before the benchmark indexes exist.
5. `sql/04b-indexed-plans-and-comparison.sql` creates the benchmark indexes, gathers statistics, records indexed plans and measurements, compares result signatures, and reports index sizes.

In pgAdmin, execute each `EXPLAIN` statement separately when capturing a plan screenshot so the complete plan, node names, buffers and Execution Time are visible. Execute the rest of each script to populate the median and result-parity outputs. A measurement consists of one warm-up followed by seven recorded runs; the reported median excludes the warm-up.

## Benchmark data and queries

The isolated schema contains 50,000 fictional customers, 100,000 accounts and 500,000 transactions. Rows are generated deterministically with savings and current accounts, deposits, withdrawals and transfers, a small failed-status share, and transaction dates distributed across one year. These benchmark records are synthetic and are not a second copy of the portfolio's three sample customers.

The comparison covers:

- A selective customer-account join.
- An aggregate of account balances by account type.
- A recent activity lookup for one account, including transactions where it is the source or destination.
- A one-week transaction-date report.

The scripts compare each query before and after creating targeted indexes. They store baseline and indexed result counts and hashes to check that the returned row sets match. I record the planner's actual scan choice; the scripts do not force PostgreSQL to use an index. A full-table aggregate may still use a sequential scan, which is useful evidence about when an index helps.

## Small-table result

The earlier three-account experiment recorded about 0.108 ms before and 0.133 ms after adding `idx_accounts_balance`. PostgreSQL used sequential scans in the recorded plans. The table is too small for that one pair of timings to establish a general performance effect. The repeatable small-table script resets only its exercise index so it can be run again.

## Evidence to capture after running the benchmark

Save full pgAdmin plan output under `evidence/` using these names:

- `baseline-01-customer-account-join.png`
- `baseline-02-account-type-aggregate.png`
- `baseline-03-account-transaction-history.png`
- `benchmark-data-counts.png`
- `baseline-04-date-range-report.png`
- `indexed-01-customer-account-join.png`
- `indexed-02-account-type-aggregate.png`
- `indexed-03-account-transaction-history.png`
- `indexed-04-date-range-report.png`
- `benchmark-result-parity.png`
- `benchmark-median-summary.png`
- `benchmark-index-sizes.png`

Capture the complete query plan, including its node types, shared buffer counts and Execution Time. Do not crop off the plan summary. The plan screenshots still need to be captured from pgAdmin and committed. The measurements below came from a disposable PostgreSQL 18.6 validation cluster on my Windows machine because the usual server was not running during the audit. I will rerun the scripts on the PostgreSQL instance used for my portfolio, capture its outputs, and update these figures if its planner choices or medians differ.


## Local benchmark results

I verified the scripts in a disposable PostgreSQL 18.6 cluster on this Windows machine. It contained 50,000 customers, 100,000 accounts and 500,000 transactions. The table below reports medians from seven measured runs after one warm-up for each query and stage. These are genuine local validation results, but they are provisional until I capture the corresponding plans from my regular pgAdmin connection.

| Query | Baseline median (ms) | Indexed median (ms) | Shared buffer hits, baseline to indexed | Observed plan change |
| --- | ---: | ---: | ---: | --- |
| Customer-account lookup | 7.209 | 0.029 | 938 to 6 | Accounts sequential scan to `p2_accounts_customer_id_idx` index scan |
| Account-type aggregate | 43.672 | 25.871 | 935 to 935 | Sequential scan in both plans; do not attribute the timing difference to the covering index |
| Account transaction history | 145.813 | 0.060 | 10,728 to 12 | Parallel sequential scans to bitmap index and heap scans on source/destination history indexes |
| One-week date report | 93.848 | 8.180 | 5,336 to 5,390 | Parallel sequential scan to bitmap index and heap scans |

All four baseline and indexed result signatures matched (2, 2, 6 and 6 result rows by query, respectively). Shared read blocks were zero in the measured runs, so these figures describe warm-cache behaviour on this local cluster. The date report touched slightly more shared blocks with the index; its timing should be interpreted with the measured plan and local context.

The five benchmark indexes occupied 1,992 kB, 3,816 kB, 24 MB, 24 MB and 28 MB, respectively. They add storage and create extra work on inserts and updates. The local timings are not production guarantees. I will use the actual pgAdmin outputs from my regular PostgreSQL instance for final screenshots and revise the recorded values if needed.

## Limitations

The benchmark is synthetic and runs on one local PostgreSQL instance. Warm-cache medians and planner choices describe this machine, this data distribution and these queries; they are not production-scale guarantees. Indexes consume storage and add work to inserts and updates. The small-table result remains useful because PostgreSQL can correctly prefer a sequential scan when a table is tiny.
