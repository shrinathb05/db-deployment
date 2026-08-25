USE app_test_db;

DROP PROCEDURE IF EXISTS sp_archive_inactive_employees;

DELIMITER //

CREATE PROCEDURE sp_archive_inactive_employees(
    IN p_reason VARCHAR(255)
)
BEGIN
    DECLARE v_archived_count INT DEFAULT 0;

    -- Copy inactive employees into archive
    INSERT INTO employee_archive (
        emp_id, first_name, last_name, email, department, designation, salary, hire_date, archive_reason
    )
    SELECT emp_id, first_name, last_name, email, department, designation, salary, hire_date, IFNULL(p_reason, 'Scheduled Maintenance Archival')
    FROM employee
    WHERE status = 'INACTIVE';

    SET v_archived_count = ROW_COUNT();

    -- Delete archived rows from primary table
    IF v_archived_count > 0 THEN
        DELETE FROM employee
        WHERE status = 'INACTIVE';

        SELECT 
            'Archival Complete' AS result,
            v_archived_count AS records_archived,
            p_reason AS reason;
    ELSE
        SELECT 'No inactive employee records found for archival' AS result;
    END IF;
END //

DELIMITER ;

-- Test Execution
CALL sp_archive_inactive_employees('Manual MySQL Routine Test');

-- Verify results
SELECT * FROM employee_archive;
SELECT emp_id, first_name, status FROM employee;