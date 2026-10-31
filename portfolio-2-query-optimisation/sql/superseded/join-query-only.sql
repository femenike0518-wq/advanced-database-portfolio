EXPLAIN ANALYZE
SELECT
    c.full_name,
    a.account_number,
    a.balance
FROM customers AS c
JOIN accounts AS a
    ON c.customer_id = a.customer_id
WHERE a.balance > 40000;
