═══════════════════════════════════════════════════════════════════════════════
-- PHASE 2: ADVANCED ANALYSIS (4 Queries)
-- ═══════════════════════════════════════════════════════════════════════════════

-- QUERY 4: Fraud Detection & Risk Analysis
-- Purpose: Identify fraudulent transactions and at-risk customers
-- Finding: Monitor card activity, prevent fraud losses
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.customer_tier,
    COUNT(ct.card_trans_id) AS total_transactions,
    COUNT(CASE WHEN ct.is_fraudulent = TRUE THEN 1 END) AS fraudulent_transactions,
    CASE 
        WHEN COUNT(ct.card_trans_id) = 0 THEN 0
        ELSE ROUND(
            COUNT(CASE WHEN ct.is_fraudulent = TRUE THEN 1 END)::NUMERIC / 
            COUNT(ct.card_trans_id) * 100, 2
        )
    END AS fraud_percentage,
    SUM(CASE WHEN ct.is_fraudulent = TRUE THEN ct.amount ELSE 0 END) AS fraud_amount,
    cc.card_status
FROM customers c
JOIN credit_cards cc ON c.customer_id = cc.customer_id
LEFT JOIN card_transactions ct ON cc.card_id = ct.card_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_tier, cc.card_status
ORDER BY fraud_amount DESC;
-- Result: 0 fraud detected (all cards safe, status ACTIVE)

---

-- QUERY 5: Loan Default Risk Analysis
-- Purpose: Identify customers with defaulted loans and risk levels
-- Finding: Bob Johnson has $20K defaulted = MEDIUM RISK
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.customer_tier,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_amount,
    COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) AS defaulted_loans,
    SUM(CASE WHEN l.loan_status = 'Defaulted' THEN l.loan_amount ELSE 0 END) AS defaulted_amount,
    ROUND(
        COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END)::NUMERIC / 
        COUNT(DISTINCT l.loan_id) * 100, 2
    ) AS default_rate,
    CASE 
        WHEN COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) > 1 THEN 'HIGH RISK'
        WHEN COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) = 1 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_level
FROM customers c
LEFT JOIN loans l ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_tier
HAVING COUNT(DISTINCT l.loan_id) > 0
ORDER BY defaulted_amount DESC;
-- Result: 1 MEDIUM RISK (Bob Johnson, $20K default), 2 LOW RISK

---

-- QUERY 6: Customer Profitability & Cross-Sell Opportunities
-- Purpose: Identify customers with product gaps for cross-selling
-- Finding: Alice Brown and Charlie Wilson have cross-sell opportunities
WITH customer_products AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        COUNT(DISTINCT a.account_id) AS account_count,
        COUNT(DISTINCT cc.card_id) AS card_count,
        COUNT(DISTINCT l.loan_id) AS loan_count,
        SUM(a.account_balance) AS total_balance,
        SUM(l.loan_amount) AS total_loans_amount
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN credit_cards cc ON c.customer_id = cc.customer_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    account_count,
    card_count,
    loan_count,
    (account_count + card_count + loan_count) AS total_products,
    total_balance,
    total_loans_amount,
    CASE 
        WHEN (account_count + card_count + loan_count) >= 3 THEN 'HIGH VALUE'
        WHEN (account_count + card_count + loan_count) = 2 THEN 'MEDIUM VALUE'
        ELSE 'LOW VALUE'
    END AS customer_value,
    CASE 
        WHEN account_count >= 1 AND card_count = 0 THEN 'Cross-sell Credit Card'
        WHEN account_count >= 1 AND loan_count = 0 THEN 'Cross-sell Loan'
        WHEN card_count >= 1 AND account_count = 0 THEN 'Cross-sell Account'
        ELSE 'Well-Served'
    END AS cross_sell_opportunity
FROM customer_products
ORDER BY total_products DESC;
-- Result: John Smith (4 products, HIGH VALUE), Alice Brown (Cross-sell Loan), Charlie Wilson (Cross-sell Credit Card)

---

-- QUERY 7: Customer Segment Analysis with ROI Potential
-- Purpose: Segment customers by tier and calculate profitability
-- Finding: Platinum = $14.75K annual revenue, Silver has 1 default
SELECT 
    c.customer_tier,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    ROUND(AVG(a.account_balance), 2) AS avg_balance,
    SUM(a.account_balance) AS total_balance,
    COUNT(DISTINCT CASE WHEN t.transaction_date > CURRENT_DATE - INTERVAL '90 days' THEN c.customer_id END) AS active_90days,
    ROUND(
        COUNT(DISTINCT CASE WHEN t.transaction_date > CURRENT_DATE - INTERVAL '90 days' THEN c.customer_id END)::NUMERIC / 
        COUNT(DISTINCT c.customer_id) * 100, 2
    ) AS activity_rate,
    COUNT(DISTINCT l.loan_id) AS loan_count,
    SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaults,
    ROUND(
        SUM(a.account_balance) * 0.05, 2
    ) AS estimated_annual_revenue,
    CASE 
        WHEN c.customer_tier = 'Platinum' THEN 'VIP Program + Personal Manager'
        WHEN c.customer_tier = 'Gold' THEN 'Premium Services + Higher Limits'
        WHEN c.customer_tier = 'Silver' THEN 'Standard + Upgrade Path'
        ELSE 'Entry + Growth Opportunity'
    END AS recommended_strategy
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
LEFT JOIN loans l ON c.customer_id = l.customer_id
GROUP BY c.customer_tier
ORDER BY total_balance DESC;
-- Result: Platinum $14.75K, Gold $1.5K, Silver $2.25K (1 default), Bronze $750

---

-- ═══════════════════════════════════════════════════════════════════════════════
-- END OF SQL QUERIES
-- ═══════════════════════════════════════════════════════════════════════════════
