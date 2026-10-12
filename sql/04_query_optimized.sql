-- П.4: тот же запрос по оптимизированной таблице.
SELECT
    us_state,
    argMax(cat_id, amount) AS category,
    max(amount)            AS max_amount
FROM default.transactions_opt
GROUP BY us_state
ORDER BY us_state
