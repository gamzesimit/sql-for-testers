# Schema notes

The queries here are written against Akaunting, an open source accounting
platform. The table names carry a prefix set at install time, `asd_` in this
environment. Change the prefix and every query works against another install.

## The tables the queries touch

| Table | What it holds |
|---|---|
| `documents` | One row per invoice or bill: number, dates, status, total, currency |
| `document_items` | One row per line: name, quantity, price, line total |
| `document_totals` | One row per figure on the document, keyed by `code`: sub_total, tax, discount, total |
| `transactions` | Payments in and out, linked to an account and sometimes to a document |
| `contacts` | Customers and vendors |
| `accounts` | Bank accounts |
| `taxes` | Tax rates |
| `currencies` | Currency codes and their rates |
| `companies` | The tenant every other row belongs to |

## Two things worth knowing before writing a query here

**Soft deletes.** Almost every table carries `deleted_at`. A row with a value in
it is deleted as far as the application is concerned and invisible on screen. A
query that forgets `deleted_at IS NULL` reports figures nobody can see, which is
worse than reporting nothing.

**Multi tenancy.** Every row carries `company_id`. A query that leaves it out
sums across tenants. On a single tenant install that looks fine and stays wrong.
