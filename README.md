# SQL for testers

Queries that check an accounting database is telling the truth. Written against
an open source accounting platform, and written so that a clean database returns
no rows.

| File | What it checks |
|---|---|
| `queries/01-invoice-totals.sql` | The stored total agrees with the sum of the lines, the printed total agrees with sub total plus tax minus discount, and each line agrees with quantity times price |
| `queries/02-referential-integrity.sql` | No invoice, line, or transaction points at a parent that has been deleted, and nothing belongs to a company that is gone |
| `queries/03-data-quality.sql` | Tax rates inside a sane range, currency rates above zero, dates in the right order, amounts rounded to the cent |
| `queries/04-duplicates-and-reconciliation.sql` | No duplicate invoice numbers, no repeated payment on the same day, and every invoice marked paid has payments that add up |

Schema notes: [schema/notes.md](schema/notes.md)
Proving the checks catch something: [docs/proving-the-checks.md](docs/proving-the-checks.md)
How to run them: [docs/how-to-run.md](docs/how-to-run.md)

## Why an empty result is the pass

A query that returns rows on success has to be read and understood. A query that
returns rows only when something is wrong can be handed to anyone. Every check
here is written the second way, so the output is either nothing or a list of
things to look at.

## Where these come from

Six years of month end close. The checks an accountant runs by hand before
signing off are the same checks a test suite should run on every build: does the
total equal its parts, does the ledger balance, is anything paid twice, does
every record still point at something that exists.

The arithmetic ones matter most. A total computed separately from its lines can
drift by a cent and nothing on screen says so, which is exactly the kind of
fault that is cheap to catch here and expensive to find in a reconciliation.
