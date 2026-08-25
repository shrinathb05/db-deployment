USE app_test_db;

INSERT INTO customer_records (username, email, status, balance) VALUES
('shree_b', 'shree@example.com', 'ACTIVE', 1500.00),
('rajesh_k', 'rajesh@example.com', 'PENDING', 250.50),
('sneha_m', 'sneha@example.com', 'ACTIVE', 3200.75),
('test_user', 'temp@example.com', 'INACTIVE', 0.00);

SELECT * FROM customer_records;