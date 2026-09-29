-- Duplicates and reconciliation
--
-- The checks an accountant runs at month end, written as queries so they can
-- run on every build instead of once a month.

-- 1. Two invoices carrying the same number. Expected: no rows.
--    An invoice number is the thing a customer quotes when they call.
SELECT company_id, document_number, COUNT(*) AS occurrences
FROM asd_documents
WHERE type = 'invoice'
  AND deleted_at IS NULL
GROUP BY company_id, document_number
HAVING COUNT(*) > 1;

-- 2. The same amount paid to the same contact on the same day, more than once.
--    Not always wrong, but this is how a double payment looks.
SELECT contact_id, paid_at, amount, COUNT(*) AS occurrences
FROM asd_transactions
WHERE deleted_at IS NULL
GROUP BY contact_id, DATE(paid_at), amount
HAVING COUNT(*) > 1;

-- 3. Invoices marked paid where the payments do not add up to the total.
--    Expected: no rows. This is the reconciliation break that matters most,
--    because the invoice looks settled on every screen.
SELECT
    d.id,
    d.document_number,
    d.amount                          AS invoice_total,
    COALESCE(SUM(t.amount), 0)        AS paid,
    ROUND(d.amount - COALESCE(SUM(t.amount), 0), 2) AS outstanding
FROM asd_documents d
LEFT JOIN asd_transactions t
       ON t.document_id = d.id
      AND t.deleted_at IS NULL
WHERE d.type = 'invoice'
  AND d.status = 'paid'
  AND d.deleted_at IS NULL
GROUP BY d.id, d.document_number, d.amount
HAVING ABS(d.amount - COALESCE(SUM(t.amount), 0)) > 0.005;

-- 4. Money by currency, to see at a glance whether a conversion has gone wrong.
--    Not an assertion, a sanity view: one currency holding an implausible share
--    of the total is usually a rate fault rather than a busy month.
SELECT
    currency_code,
    COUNT(*)              AS invoices,
    ROUND(SUM(amount), 2) AS total
FROM asd_documents
WHERE type = 'invoice'
  AND deleted_at IS NULL
GROUP BY currency_code
ORDER BY total DESC;
