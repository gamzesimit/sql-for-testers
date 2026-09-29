-- Proving the checks catch something
--
-- Every block inserts one fault, runs the check, and rolls back. The database
-- is left exactly as it was found.

-- Tax rate outside a sane range -------------------------------------------
START TRANSACTION;
SELECT COUNT(*) AS tax_rows_before_fault
FROM asd_taxes WHERE deleted_at IS NULL AND (rate < 0 OR rate > 100);

INSERT INTO asd_taxes (company_id, name, rate, type, enabled, created_at, updated_at)
VALUES (1, 'PROOF impossible rate', 250, 'normal', 1, NOW(), NOW());

SELECT COUNT(*) AS tax_rows_after_fault
FROM asd_taxes WHERE deleted_at IS NULL AND (rate < 0 OR rate > 100);
ROLLBACK;

-- Currency rate of zero -----------------------------------------------------
START TRANSACTION;
SELECT COUNT(*) AS currency_rows_before_fault
FROM asd_currencies WHERE deleted_at IS NULL AND rate <= 0;

INSERT INTO asd_currencies (company_id, name, code, rate, enabled, `precision`, symbol, symbol_first, decimal_mark, thousands_separator, created_at, updated_at)
VALUES (1, 'PROOF zero rate', 'ZZZ', 0, 1, 2, 'Z', 1, '.', ',', NOW(), NOW());

SELECT COUNT(*) AS currency_rows_after_fault
FROM asd_currencies WHERE deleted_at IS NULL AND rate <= 0;
ROLLBACK;

-- Invoice due before it was issued -----------------------------------------
START TRANSACTION;
SELECT COUNT(*) AS date_rows_before_fault
FROM asd_documents WHERE deleted_at IS NULL AND due_at < issued_at;

INSERT INTO asd_documents
  (company_id, type, document_number, status, issued_at, due_at, amount,
   currency_code, currency_rate, category_id, contact_id, contact_name,
   created_at, updated_at)
VALUES
  (1, 'invoice', 'PROOF-DATE-001', 'draft', '2026-06-01 00:00:00',
   '2026-05-01 00:00:00', 100.00, 'USD', 1, 1, 1, 'Proof customer', NOW(), NOW());

SELECT COUNT(*) AS date_rows_after_fault
FROM asd_documents WHERE deleted_at IS NULL AND due_at < issued_at;
ROLLBACK;

-- Duplicate invoice number --------------------------------------------------
START TRANSACTION;
SELECT COUNT(*) AS duplicate_groups_before_fault FROM (
  SELECT document_number FROM asd_documents
  WHERE type = 'invoice' AND deleted_at IS NULL
  GROUP BY company_id, document_number HAVING COUNT(*) > 1
) AS before_fault;

INSERT INTO asd_documents
  (company_id, type, document_number, status, issued_at, due_at, amount,
   currency_code, currency_rate, category_id, contact_id, contact_name,
   created_at, updated_at)
VALUES
  (1, 'invoice', 'PROOF-DUP-001', 'draft', NOW(), NOW(), 10.00, 'USD', 1, 1, 1, 'Proof customer', NOW(), NOW()),
  (1, 'invoice', 'PROOF-DUP-001', 'draft', NOW(), NOW(), 10.00, 'USD', 1, 1, 1, 'Proof customer', NOW(), NOW());

SELECT COUNT(*) AS duplicate_groups_after_fault FROM (
  SELECT document_number FROM asd_documents
  WHERE type = 'invoice' AND deleted_at IS NULL
  GROUP BY company_id, document_number HAVING COUNT(*) > 1
) AS after_fault;
ROLLBACK;
