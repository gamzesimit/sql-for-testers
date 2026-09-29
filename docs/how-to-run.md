# Running the queries

## Against the container used here

```bash
git clone https://github.com/akaunting/docker akaunting-docker
cd akaunting-docker
cp env/db.env.example env/db.env
cp env/run.env.example env/run.env
AKAUNTING_SETUP=true docker compose up -d
```

Then, from this repository:

```bash
docker compose -f ../akaunting-docker/docker-compose.yml exec -T akaunting-db \
  mariadb -uadmin -p"$DB_PASSWORD" akaunting < queries/01-invoice-totals.sql
```

## What a pass looks like

Every query in files 01 to 03 is written so that a correct database returns no
rows. An empty result is the pass. That is deliberate: a query that returns rows
on success has to be read carefully, while a query that returns rows only when
something is wrong can be run by anyone and understood in a second.

File 04 mixes the two. The first three queries return nothing when the data is
sound; the last one is a sanity view that always returns rows and is there to be
looked at rather than asserted on.

## Result on the environment tested

All four files run clean. No arithmetic break, no orphaned row, no tax or
currency rate outside a sane range, no duplicate invoice number, no invoice
marked paid without matching payments.

That is worth recording. A set of checks that has never returned a row on any
database is a set of checks nobody has proved works, so each one was also run
against a deliberately broken copy to confirm it does catch what it claims to.
