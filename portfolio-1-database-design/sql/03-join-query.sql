SELECT
    c.customer_id,
    c.full_name,
    c.email,
    a.account_number,
    a.account_type,
    a.balance
FROM customers AS c
JOIN accounts AS a
    ON c.customer_id = a.customer_id
ORDER BY c.customer_id;