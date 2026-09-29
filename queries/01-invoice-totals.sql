-- Invoice arithmetic
--
-- The interface prints a total. These queries ask the database whether that
-- total agrees with the lines it was built from. A total computed separately
-- from its parts can drift, and the drift is invisible on screen.
--
-- Schema note: Akaunting stores each invoice in `documents` and each figure
-- that makes it up in `document_totals`, with a `code` of sub_total, tax,
-- discount or total.

-- 1. Every invoice where the stored total does not equal the sum of its lines.
--    Expected: no rows.
SELECT
    d.id,
    d.document_number,
    d.amount                                   AS stored_total,
    ROUND(SUM(di.total), 2)                    AS sum_of_lines,
    ROUND(d.amount - SUM(di.total), 2)         AS difference
FROM asd_documents d
JOIN asd_document_items di ON di.document_id = d.id
WHERE d.type = 'invoice'
  AND d.deleted_at IS NULL
GROUP BY d.id, d.document_number, d.amount
HAVING ABS(d.amount - SUM(di.total)) > 0.005;

-- 2. Every invoice whose printed total does not equal sub total plus tax minus
--    discount. Expected: no rows.
SELECT
    d.id,
    d.document_number,
    MAX(CASE WHEN t.code = 'sub_total' THEN t.amount END) AS sub_total,
    MAX(CASE WHEN t.code = 'tax'       THEN t.amount END) AS tax,
    MAX(CASE WHEN t.code = 'discount'  THEN t.amount END) AS discount,
    MAX(CASE WHEN t.code = 'total'     THEN t.amount END) AS total
FROM asd_documents d
JOIN asd_document_totals t ON t.document_id = d.id
WHERE d.type = 'invoice'
  AND d.deleted_at IS NULL
GROUP BY d.id, d.document_number
HAVING ABS(
    COALESCE(MAX(CASE WHEN t.code = 'total' THEN t.amount END), 0)
  - (
      COALESCE(MAX(CASE WHEN t.code = 'sub_total' THEN t.amount END), 0)
      + COALESCE(MAX(CASE WHEN t.code = 'tax' THEN t.amount END), 0)
      - COALESCE(MAX(CASE WHEN t.code = 'discount' THEN t.amount END), 0)
    )
) > 0.005;

-- 3. Line items whose amount does not equal quantity times price.
--    Expected: no rows. This is where a rounding fault shows first, because a
--    line is rounded before it is summed.
SELECT
    di.document_id,
    di.name,
    di.quantity,
    di.price,
    di.total                                        AS stored_line_total,
    ROUND(di.quantity * di.price, 2)                AS computed,
    ROUND(di.total - (di.quantity * di.price), 2)   AS difference
FROM asd_document_items di
JOIN asd_documents d ON d.id = di.document_id
WHERE d.deleted_at IS NULL
  AND ABS(di.total - (di.quantity * di.price)) > 0.005;
