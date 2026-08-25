USE app_test_db;

-- Patch: Activate pending user and credit promotional balance
UPDATE customer_records
SET status = 'ACTIVE',
    balance = balance + 100.00
WHERE email = 'rajesh@example.com';

SELECT id, username, status, balance, updated_at FROM customer_records WHERE email = 'rajesh@example.com';