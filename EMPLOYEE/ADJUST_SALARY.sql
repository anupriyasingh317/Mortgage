CREATE OR REPLACE PROCEDURE ADJUST_SALARY (
    p_employee_id    IN NUMBER,
    p_adjustment     IN NUMBER,
    p_action         IN VARCHAR2,
    p_new_salary     OUT NUMBER
)
IS
    v_old_salary    EMPLOYEES.SALARY%TYPE;
    v_max_bonus     CONSTANT NUMBER := 10000;
    v_max_deduction CONSTANT NUMBER := 5000;
BEGIN
    -- Fetch the current salary
    SELECT SALARY
    INTO v_old_salary
    FROM EMPLOYEES
    WHERE EMPLOYEE_ID = p_employee_id;

    -- Perform salary adjustment
    IF p_action = 'BONUS' THEN
        IF p_adjustment > v_max_bonus THEN
            RAISE_APPLICATION_ERROR(-20101, 'Bonus exceeds maximum limit.');
        END IF;
        p_new_salary := v_old_salary + p_adjustment;

    ELSIF p_action = 'DEDUCTION' THEN
        IF p_adjustment > v_max_deduction THEN
            RAISE_APPLICATION_ERROR(-20102, 'Deduction exceeds maximum limit.');
        END IF;
        p_new_salary := v_old_salary - p_adjustment;

    ELSE
        RAISE_APPLICATION_ERROR(-20103, 'Invalid action. Must be BONUS or DEDUCTION.');
    END IF;

    -- Update employee salary
    UPDATE EMPLOYEES
    SET SALARY = p_new_salary
    WHERE EMPLOYEE_ID = p_employee_id;

    -- Log adjustment
    INSERT INTO SALARY_AUDIT (
        AUDIT_ID, EMPLOYEE_ID, OLD_SALARY, NEW_SALARY, ACTION, ACTION_DATE
    )
    VALUES (
        SALARY_AUDIT_SEQ.NEXTVAL, p_employee_id, v_old_salary, p_new_salary, p_action, SYSDATE
    );
END ADJUST_SALARY;
/
