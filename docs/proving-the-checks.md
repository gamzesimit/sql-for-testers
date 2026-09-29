# Proving the checks catch something

A query that has never returned a row is a query nobody has proved works. Each
check below was run twice: once against the clean database, where it must return
nothing, and once against a copy with a fault inserted, where it must return the
faulty row and nothing else.

The faults are inserted in a transaction and rolled back, so the database is
left as it was found.

## How to run it

```bash
docker compose -f ../akaunting-docker/docker-compose.yml exec -T akaunting-db \
  mariadb -uadmin -p"$DB_PASSWORD" akaunting < proofs/prove-checks.sql
```

## What the proof does

| Check | Fault inserted | Expected |
|---|---|---|
| Tax rate range | A rate of 250 | One row returned, the row inserted |
| Currency rate | A rate of 0 | One row returned |
| Date order | An invoice due before it was issued | One row returned |
| Duplicate invoice number | A second invoice with an existing number | One row returned |

Each block prints the count before the fault and the count after, then rolls
back. A check that returns the same count both times has not proved anything.

## Result on the environment tested

| Check | Before | After |
|---|---|---|
| Tax rate range | 0 | 1 |
| Currency rate | 0 | 1 |
| Date order | 0 | 1 |
| Duplicate invoice number | 0 | 1 |

All four went from nothing to exactly the row that was inserted, and the
database was left as it was found.

## The three checks not proved this way

Invoice arithmetic, referential integrity and the reconciliation check need a
document with lines and payments to break in a realistic way, which is more
setup than a rollback block should carry. They are covered instead by the
automated suites, where a broken total shows up as a failing test.
