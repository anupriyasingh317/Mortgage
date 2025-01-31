CREATE OR REPLACE PROCEDURE PROC_MANAGE_EMPLOYEE_SALARY (
    p_department_id   IN NUMBER,
    p_adjustment      IN NUMBER,
    p_action          IN VARCHAR2
)
IS
    CURSOR emp_cursor IS
        SELECT EMPLOYEE_ID, NAME
        FROM EMPLOYEES
        WHERE DEPARTMENT_ID = p_department_id;

    v_employee_id    EMPLOYEES.EMPLOYEE_ID%TYPE;
    v_employee_name  EMPLOYEES.NAME%TYPE;
    v_new_salary     EMPLOYEES.SALARY%TYPE;
    v_promotion      VARCHAR2(10);
BEGIN
    -- Loop through employees in the department
    OPEN emp_cursor;
    LOOP
        FETCH emp_cursor INTO v_employee_id, v_employee_name;
        EXIT WHEN emp_cursor%NOTFOUND;

        -- Adjust salary
        ADJUST_SALARY(p_employee_id, p_adjustment, p_action, v_new_salary);

        -- Check promotion eligibility
        PROMOTION_ELIGIBILITY(p_employee_id, v_promotion);

        -- Output results
        DBMS_OUTPUT.PUT_LINE('Employee: ' || v_employee_name ||
                             ', New Salary: ' || v_new_salary ||
                             ', Promotion Eligible: ' || v_promotion);
    END LOOP;
    CLOSE emp_cursor;

    -- Commit all changes
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Salary adjustments and promotions processed for Department: ' || p_department_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END PROC_MANAGE_EMPLOYEE_SALARY;
/