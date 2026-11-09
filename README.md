 MIT 8103 Advanced Database Systems Portfolio

 Selected case study: SwiftBank

SwiftBank is a fictional banking system to handle customers with both savings and current accounts. The database can be used by customers, bank staff, and administrators. The database contains customer details (contact information), their account, balance, transaction type, amount, status, date and account reference. The system allows for account creation/maintenance, deposits, withdrawals, transfers, viewing transaction history and checking transactions.

 Portfolio guide

| Portfolio | Focus | Start here |
| --- | --- | --- |
| 1 | Relational design and modelling | [Portfolio 1 README](portfolio-1-database-design/README.md) |
| 2 | Query processing and optimisation | [Portfolio 2 README](portfolio-2-query-optimisation/README.md) |
| 3 | Transactions and concurrency | [Portfolio 3 README](portfolio-3-transactions-concurrency/README.md) |
| 4 | NoSQL and advanced data models | [Portfolio 4 README](portfolio-4-nosql/README.md) |
| 5 | Distributed and cloud database exercise | [Portfolio 5 README](portfolio-5-distributed-cloud/README.md) |

Each portfolio README identifies the work, its evidence and relevant limitations.

 Repository map

| Path | Contents |
| --- | --- |
| [portfolio-1-database-design/](portfolio-1-database-design/) | Relational schema, seed data, ER diagram. Scripts in `sql/`, screenshots and diagrams in `evidence/`. Final ER: `evidence/er-diagram-final.png`. |
| [portfolio-2-query-optimisation/](portfolio-2-query-optimisation/) | Query plans and benchmark experiment. Canonical SQL in `sql/`; earlier one-statement files in `sql/superseded/`; screenshots in `evidence/`. |
| [portfolio-3-transactions-concurrency/](portfolio-3-transactions-concurrency/) | Commit, rollback and two-session isolation. Scripts in `sql/`, screenshots in `evidence/`. |
| [portfolio-4-nosql/](portfolio-4-nosql/) | MongoDB document example. Commands in `mongodb/`, screenshots in `evidence/`. |
| [portfolio-5-distributed-cloud/](portfolio-5-distributed-cloud/) | PostgreSQL 18.6 local asynchronous streaming standby, verification scripts and distributed/cloud design notes. PowerShell setup instructions are in the P5 README; screenshots are in `evidence/`. |

 Tools

- PostgreSQL (18.6) – For relational database design, query planning, transaction testing and local replication.

- MongoDB Community Server – To run the SwiftBank document example using `mongosh`.

- Git + GitHub – For version control and storing evidence.

 AI-use declaration

 Tools used

ChatGPT and Codex were utilized when completing this portfolio.

 What I used each tool for

ChatGPT was used to help understand what the task was asking me to do. Codex was used to help create my portfolios, fix any errors, check my work and help write the final documentation. Codex was also used to help sort my portfolio into the different sections (SQL, MongoDB, Evidence). This involved renaming the screenshot and script files so that the links in the README would still be correct.

 How I reviewed and verified the work

All scripts (SQL and MongoDB) were executed on my own instances of PostgreSQL 18.6 and MongoDB. Checked that everything was returning the correct values. Negative testing was done. Checked that queries were returning consistent results. Screenshots were taken by me. Checked links in README. After organizing and renaming files. Checked work done with AI assistance. I take responsibility for the work in my portfolio.

My final documentation was drafted with Codex's assistance. I am accountable for the accuracy of that wording after reviewing it.
