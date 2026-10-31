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

## Benchmark evidence

I captured the following outputs from my PostgreSQL 18.6 instance. Long plans use a `-b.png` continuation; read the paired images together to see the full plan and Execution Time.

The earlier three-account exercise is shown in [its baseline plan](evidence/01-baseline-execution-plan.png), [post-index plan](evidence/02-indexed-execution-plan.png), [balance filter plan](evidence/03-balance-filter-plan.png), [account index list](evidence/04-accounts-index-list.png) and [balance summary](evidence/05-account-balance-summary.png).

- Data counts: [benchmark-data-counts.png](evidence/benchmark-data-counts.png)
- Baseline customer-account join: [first part](evidence/baseline-01-customer-account-join.png)
- Baseline account-type aggregate: [baseline-02-account-type-aggregate.png](evidence/baseline-02-account-type-aggregate.png)
- Baseline account transaction history: [first part](evidence/baseline-03-account-transaction-history.png), [continuation](evidence/baseline-03-account-transaction-history-b.png)
- Baseline date-range report: [first part](evidence/baseline-04-date-range-report.png), [continuation](evidence/baseline-04-date-range-report-b.png)
- Indexed customer-account join: [first part](evidence/indexed-01-customer-account-join.png), [continuation](evidence/indexed-01-customer-account-join-b.png)
- Indexed account-type aggregate: [indexed-02-account-type-aggregate.png](evidence/indexed-02-account-type-aggregate.png)
- Indexed account transaction history: [first part](evidence/indexed-03-account-transaction-history.png), [continuation](evidence/indexed-03-account-transaction-history-b.png)
- Indexed date-range report: [indexed-04-date-range-report.png](evidence/indexed-04-date-range-report.png)
- Result parity: [benchmark-result-parity.png](evidence/benchmark-result-parity.png)
- Seven-run median comparison: [benchmark-median-summary.png](evidence/benchmark-median-summary.png)
- Index sizes: [benchmark-index-sizes.png](evidence/benchmark-index-sizes.png)
## Local benchmark results

I ran the benchmark on my PostgreSQL 18.6 instance. It contained 50,000 customers, 100,000 accounts and 500,000 transactions. The table below reports medians from seven measured runs after one warm-up for each query and stage.

| Query | Baseline median (ms) | Indexed median (ms) | Shared buffer hits, baseline to indexed | Observed plan change |
| --- | ---: | ---: | ---: | --- |
| Customer-account lookup | 11.878 | 0.045 | 938 to 6 | Accounts sequential scan to index scan using `p2_accounts_customer_id_idx` |
| Account-type aggregate | 108.407 | 43.528 | 935 to 935 | Sequential scan in both plans; the timing difference is not attributed to the covering index |
| Account transaction history | 126.342 | 0.043 | 10,728 to 8 | Parallel sequential scans to index-only scans using the source and destination history indexes |
| One-week date report | 106.458 | 4.749 | 5,336 to 72 | Parallel sequential scan to index-only scan using `p2_transactions_date_report_idx` |

All four baseline and indexed result signatures matched (6, 2, 2 and 6 result rows for account history, account-type aggregate, customer lookup and date report, respectively). Shared read blocks were zero in the measured runs, so these figures describe warm-cache behaviour. The account-type aggregate median was lower in the indexed stage, although the planner used a sequential scan in both stages; I cannot attribute that timing difference to the covering index. These local measurements should be interpreted with the plans and machine context.

The five benchmark indexes occupied 1,992 kB, 3,816 kB, 28 MB, 24 MB and 24 MB respectively, in alphabetical order by index name. They add storage and create extra work on inserts and updates. The local timings are not production guarantees.

## Limitations

The benchmark is synthetic and runs on one local PostgreSQL instance. Warm-cache medians and planner choices describe this machine, this data distribution and these queries; they are not production-scale guarantees. Indexes consume storage and add work to inserts and updates. The small-table result remains useful because PostgreSQL can correctly prefer a sequential scan when a table is tiny.
