USE app_test_db;

DROP PROCEDURE IF EXISTS sp_apply_salary_revision;

DELIMITER //

CREATE PROCEDURE sp_apply_salary_revision(
    IN p_department VARCHAR(50),
    IN p_percentage DECIMAL(5, 2)
)
BEGIN
    DECLARE v_updated_rows INT DEFAULT 0;
    DECLARE v_min_salary DECIMAL(10, 2);
    DECLARE v_max_salary DECIMAL(10, 2);

    -- Input validation
    IF p_percentage <= 0 OR p_percentage > 50 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid increment percentage. Must be between 0.01 and 50.00';
    END IF;

    -- Apply revision
    UPDATE employee
    SET salary = ROUND(salary + (salary * (p_percentage / 100)), 2)
    WHERE department = p_department
      AND status = 'ACTIVE';

    SET v_updated_rows = ROW_COUNT();

    -- Return summary results
    IF v_updated_rows = 0 THEN
        SELECT CONCAT('No active employees found in department: ', p_department) AS status_message;
    ELSE
        SELECT MIN(salary), MAX(salary)
        INTO v_min_salary, v_max_salary
        FROM employee
        WHERE department = p_department;

        SELECT 
            'Salary Revision Applied Successfully' AS result,
            p_department AS department,
            v_updated_rows AS updated_rows,
            v_min_salary AS min_salary,
            v_max_salary AS max_salary;
    END IF;
END //

DELIMITER ;

-- Test Execution
CALL sp_apply_salary_revision('DevOps', 10.00);

-- Verify results
SELECT emp_id, first_name, department, salary, updated_at 
FROM employee 
WHERE department = 'DevOps';