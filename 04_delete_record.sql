USE app_test_db;

-- Cleanup: Delete inactive temporary test accounts
DELETE FROM customer_records
WHERE status = 'INACTIVE' AND email = 'temp@example.com';

SELECT * FROM customer_records;