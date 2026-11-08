Portfolio 2: Query Processing and Optimisation

> AI-use declaration: See the [root README](../README.md#ai-use-declaration).

Purpose

For the SwiftBank case study, I looked at balance and transaction queries using PostgresSQL query plans. In order to compare plans on more rows without altering the SwiftBank sample data, I added a larger isolated synthetic benchmark while maintaining the original three-account result as a small-table example.

Tools and environment

- PostgreSQL 18.6 and pgAdmin 4
- SQL `EXPLAIN (ANALYZE, BUFFERS)`
- Synthetic benchmark schema: `p2_benchmark`

Run order

I execute the original small-table exercise in the SwiftBank database:

1. After Portfolio 1 has created `public.customers` and `public.accounts`.  I run  `sql/01-small-table-experiment.sql`, which drops and recreates only `public.idx_accounts_balance` without changing the sample rows.
2. The sample balances by account type are reported by `sql/02-account-balance-summary.sql`

In a database where my role has the ability to create schemas, I run the larger benchmark:

3. To recreate only the `p2_benchmark` schema and load deterministic fictional rows, I run  `sql/03-build-benchmark-schema.sql`. **It drops any existing `p2_benchmark` schema**, so I save that schema for this exercise. It doesn't alter other schemas or `public`
4. Prior to the existence of benchmark indexes, baseline plans and measurements are recorded in `sql/04a-baseline-plans-and-measurements.sql`.
5. The benchmark indexes are created, statistics are collected, indexed plans and measurements are recorded, result signatures are compared and index sizes are reported in `sql/04b-indexed-plans-and-comparison.sql`.

When taking a plan screenshot in PgAdmin, I run each `EXPLAIN` statement independently so that the entire plan, node names, buffers and Execution Time are all visible. To fill in the median and result-parity outputs, I run the remainder of each script. One warm-up and seven recorded runs make up a measurement; the warm-up is not included in the reported median.

Benchmark data and queries

There are 500,000 transactions, 100,000 accounts and 50,000 fictitious customers in the isolated schema. Savings and current accounts, deposits, withdrawals and transfers, a tiny failed-status share and transaction dates spread out over a year are all generated deterministically. The three sample customers in the portfolio are not replicated in these synthetic benchmark records.

The comparison includes:

- A selective join of customer accounts.
- A total of account balances broken down by type of account.
- A recent activity lookup for a single account that includes transactions in which it is either the source or the destination.
- A report with a transaction date of one week.

Each query is compared by the scripts both before and after the targeted indexes are created. To ensure that the returned row sets match, they store hashes and baseline and indexed result counts. The scripts do not compel PostgreSQL to use an index; instead, I document the planner's actual scan selection. A sequential scan may still be used in a full-table aggregate, which is helpful information about when an index is helpful.

Small-table result

Before and after adding `idx_accounts_balance`, the previous three-account experiment recorded roughly 0.108 and 0.133 milliseconds, respectively. Sequential scans were used by PostgreSQL in the recorded plans. That one pair of timings cannot establish a general performance effect because the table is too small. Only the exercise index is reset by the repeatable small-table script so that it can be executed once more.

Benchmark evidence

From my PostgreSQL 18.6 instance, I obtained the following outputs. Long plans use a `-b.png` continuation; to view the entire plan and Execution Time, read the paired images together.

[its baseline plan](evidence/01-baseline-execution-plan.png), [post-index plan](evidence/02-indexed-execution-plan.png), [balance filter plan](evidence/03-balance-filter-plan.png), [account index list](evidence/04-accounts-index-list.png) and [balance summary](evidence/05-account-balance-summary.png) all display the previous three-account exercise.

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
Local benchmark results

I used my PostgreSQL 18.6 instance to run the benchmark. There were 500,000 transactions, 100,000 accounts, and 50,000 customers. For each query and stage, the table below shows the medians from seven measured runs following one warm-up.

| Query | Baseline median (ms) | Indexed median (ms) | Shared buffer hits, baseline to indexed | Observed plan change |
| --- | ---: | ---: | ---: | --- |
| Customer-account lookup | 11.878 | 0.045 | 938 to 6 | Accounts sequential scan to index scan using `p2_accounts_customer_id_idx` |
| Account-type aggregate | 108.407 | 43.528 | 935 to 935 | Sequential scan in both plans; the timing difference is not attributed to the covering index |
| Account transaction history | 126.342 | 0.043 | 10,728 to 8 | Parallel sequential scans to index-only scans using the source and destination history indexes |
| One-week date report | 106.458 | 4.749 | 5,336 to 72 | Parallel sequential scan to index-only scan using `p2_transactions_date_report_idx` |

Each of the four baseline and indexed result signatures (6, 2, 2, and 6 result rows for date report, account history, account-type aggregate and customer lookup, respectively) matched. These numbers illustrate warm-cache behavior because there were no shared read blocks during the measured runs. Though the planner employed a sequential scan in both stages, the account-type aggregate median was lower in the indexed stage; I am unable to link this timing discrepancy to the covering index. The plans and machine context should be taken into consideration when interpreting these local measurements.

In alphabetical order by index name, the five benchmark indexes took up 1,992 kB, 3,816 kB, 28 MB, 24 MB, and 24 MB, respectively. They increase storage and make updates and inserts more labor-intensive. Production is not guaranteed by the local timings.

Restrictions

One local PostgreSQL instance is used to run the artificial benchmark. This machine, this data distribution, and these queries are described by warm-cache medians and planner choices; they are not production-scale guarantees. Inserts and updates are made more difficult by indexes, which also use storage. Because PostgreSQL can appropriately favor a sequential scan when a table is small, the small-table result is still helpful.
