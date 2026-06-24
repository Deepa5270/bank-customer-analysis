-- BANK CUSTOMER ANALYSIS - PHASE 1

-- QUERY 1: Customer Overview
SELECT 
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    ROUND(COUNT(DISTINCT a.account_id) / COUNT(DISTINCT c.customer_id), 2) AS avg_accounts_per_customer,
    COUNT(DISTINCT CASE WHEN a.account_status = 'Active' THEN a.account_id END) AS active_accounts,
    COUNT(DISTINCT CASE WHEN a.account_status = 'Inactive' THEN a.account_id END) AS inactive_accounts
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id;
-- Result: 5 customers, 6 accounts, 1.00 avg, 5 active, 1 inactive

-- QUERY 2: Revenue by Customer Tier
SELECT 
    c.customer_tier,
    COUNT(DISTINCT c.customer_id) AS number_of_customers,
    SUM(a.account_balance) AS total_balance,
    ROUND(AVG(a.account_balance), 2) AS avg_balance_per_customer,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    ROUND(SUM(a.account_balance) / SUM(SUM(a.account_balance)) OVER () * 100, 2) AS pct_of_total_balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.account_status = 'Active'
GROUP BY c.customer_tier
ORDER BY total_balance DESC;
-- Result: Platinum = $245K (84.48%), Gold = $30K (10.34%), Bronze = $15K (5.17%)

-- QUERY 3: At-Risk Customers (Inactive 180+ days)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(a.account_balance) AS total_balance,
    MAX(t.transaction_date) AS last_transaction_date,
    (CURRENT_DATE - MAX(t.transaction_date)) AS days_inactive
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE a.account_status = 'Active'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY days_inactive DESC;
-- Result: 4 at-risk customers (870-997 days inactive)