-- Data quality
--
-- Values that are legal for the column and wrong for the business. A database
-- will happily store a negative tax rate or an invoice dated in the next
-- century; nothing complains until a report is read.

-- 1. Tax rates outside a sane range. Expected: no rows.
SELECT id, name, rate, type
FROM asd_taxes
WHERE deleted_at IS NULL
  AND (rate < 0 OR rate > 100);

-- 2. Currency rates that would break every conversion. Expected: no rows.
--    A rate of zero turns every converted figure into zero; a negative rate
--    flips the sign.
SELECT id, code, name, rate
FROM asd_currencies
WHERE deleted_at IS NULL
  AND rate <= 0;

-- 3. Invoices dated in the future or due before they were issued.
--    Expected: no rows.
SELECT id, document_number, issued_at, due_at
FROM asd_documents
WHERE deleted_at IS NULL
  AND (issued_at > NOW() + INTERVAL 1 DAY OR due_at < issued_at);

-- 4. Amounts stored with more precision than money has.
--    The column is double(15,4), so a figure can carry four decimal places.
--    Anything past the second is a rounding fault waiting to surface.
SELECT id, document_number, amount
FROM asd_documents
WHERE deleted_at IS NULL
  AND ROUND(amount, 2) <> amount;

-- 5. Contacts with no email and no phone. Not a fault on its own, but a
--    customer nobody can reach is worth counting before a mailing goes out.
SELECT id, name, type
FROM asd_contacts
WHERE deleted_at IS NULL
  AND (email IS NULL OR email = '')
  AND (phone IS NULL OR phone = '');
