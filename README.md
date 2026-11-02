# MIT 8103 Advanced Database Systems Portfolio

## SwiftBank case study

SwiftBank is a fictional banking system used throughout this individual practical portfolio. It stores customer, account and transaction records. The activities use PostgreSQL for relational design, query analysis, transactions and local replication; MongoDB for a document model.

## Portfolio guide

| Portfolio | Focus | Start here |
| --- | --- | --- |
| 1 | Relational design and modelling | [Portfolio 1 README](portfolio-1-database-design/README.md) |
| 2 | Query processing and optimisation | [Portfolio 2 README](portfolio-2-query-optimisation/README.md) |
| 3 | Transactions and concurrency | [Portfolio 3 README](portfolio-3-transactions-concurrency/README.md) |
| 4 | NoSQL and advanced data models | [Portfolio 4 README](portfolio-4-nosql/README.md) |
| 5 | Distributed and cloud database exercise | [Portfolio 5 README](portfolio-5-distributed-cloud/README.md) |

Each portfolio README identifies the work, its evidence and relevant limitations.

## Repository map

| Path | Contents |
| --- | --- |
| [portfolio-1-database-design/](portfolio-1-database-design/) | Relational schema, seed data, ER diagram. Scripts in `sql/`, screenshots and diagrams in `evidence/`. Final ER: `evidence/er-diagram-final.png`. |
| [portfolio-2-query-optimisation/](portfolio-2-query-optimisation/) | Query plans and benchmark experiment. Canonical SQL in `sql/`; earlier one-statement files in `sql/superseded/`; screenshots in `evidence/`. |
| [portfolio-3-transactions-concurrency/](portfolio-3-transactions-concurrency/) | Commit, rollback and two-session isolation. Scripts in `sql/`, screenshots in `evidence/`. |
| [portfolio-4-nosql/](portfolio-4-nosql/) | MongoDB document example. Commands in `mongodb/`, screenshots in `evidence/`. |
| [portfolio-5-distributed-cloud/](portfolio-5-distributed-cloud/) | PostgreSQL 18.6 local asynchronous streaming standby, verification scripts and distributed/cloud design notes. PowerShell setup instructions are in the P5 README; screenshots are in `evidence/`. |

## Tools

- PostgreSQL 18.6 and pgAdmin for relational design, query plans, transaction tests and local replication.
- MongoDB Community Server and `mongosh` for the SwiftBank document example.
- Git and GitHub for version control and evidence storage.

## Submission checks

Before submitting, confirm that the evidence files open, the GitHub repository is accessible to the assessor, and the commit history shows the development work. The ZIP archive does not include Git history, so commit history must be checked in GitHub.

## AI-use declaration

### Tools used

I used ChatGPT and Codex while completing this portfolio.

### What I used each tool for

I used ChatGPT to understand the assignment and the tasks I needed to complete. I used Codex to help build my portfolios, correct mistakes, review my work, and draft my final documentation.

### How I reviewed and verified the work

I ran every SQL and MongoDB script on my own PostgreSQL 18.6 and MongoDB instances, checked results against expected values, reviewed the negative tests, checked query result parity, and captured my own screenshots. I reviewed the AI-assisted work and take responsibility for the submitted portfolio and its explanations.

Codex helped draft my final documentation. I reviewed that wording and am responsible for its accuracy.
