
CREATE TABLE IF NOT EXISTS employee_backup AS
SELECT * FROM employee;

SELECT 'Backup completed successfully' AS message;