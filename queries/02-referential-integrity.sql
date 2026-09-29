-- Records that point at nothing
--
-- A row whose parent has been deleted does not raise an error. It shows up as a
-- blank name on a screen, or as a figure in a report that belongs to nobody.
-- These queries find them before a customer does.

-- 1. Invoices whose customer no longer exists. Expected: no rows.
SELECT d.id, d.document_number, d.contact_id, d.contact_name
FROM asd_documents d
LEFT JOIN asd_contacts c ON c.id = d.contact_id AND c.deleted_at IS NULL
WHERE d.type = 'invoice'
  AND d.deleted_at IS NULL
  AND c.id IS NULL;

-- 2. Line items whose invoice no longer exists. Expected: no rows.
SELECT di.id, di.document_id, di.name
FROM asd_document_items di
LEFT JOIN asd_documents d ON d.id = di.document_id
WHERE d.id IS NULL;

-- 3. Transactions pointing at an account that is gone. Expected: no rows.
SELECT t.id, t.account_id, t.amount, t.paid_at
FROM asd_transactions t
LEFT JOIN asd_accounts a ON a.id = t.account_id AND a.deleted_at IS NULL
WHERE t.deleted_at IS NULL
  AND a.id IS NULL;

-- 4. Rows belonging to a company that no longer exists. Expected: no rows.
--    Multi tenant data is where this bites hardest: a stale company_id means
--    one tenant's figures appear in another tenant's report.
SELECT 'documents' AS source, d.id, d.company_id
FROM asd_documents d
LEFT JOIN asd_companies co ON co.id = d.company_id AND co.deleted_at IS NULL
WHERE d.deleted_at IS NULL AND co.id IS NULL
UNION ALL
SELECT 'transactions', t.id, t.company_id
FROM asd_transactions t
LEFT JOIN asd_companies co ON co.id = t.company_id AND co.deleted_at IS NULL
WHERE t.deleted_at IS NULL AND co.id IS NULL;
