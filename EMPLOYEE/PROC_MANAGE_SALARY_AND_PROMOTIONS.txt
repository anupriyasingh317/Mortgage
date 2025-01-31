SET SERVEROUTPUT ON;

DECLARE
    -- Cursor for employees in the specified department
    CURSOR emp_cursor IS
        SELECT EMPLOYEE_ID, NAME, SALARY, PERFORMANCE_RATING, HIRE_DATE
        FROM EMPLOYEES
        WHERE DEPARTMENT_ID = 10; -- Replace with input parameter if needed

    -- Employee variables
    v_employee_id      EMPLOYEES.EMPLOYEE_ID%TYPE;
    v_employee_name    EMPLOYEES.NAME%TYPE;
    v_salary           EMPLOYEES.SALARY%TYPE;
    v_performance      EMPLOYEES.PERFORMANCE_RATING%TYPE;
    v_hire_date        EMPLOYEES.HIRE_DATE%TYPE;
    v_new_salary       EMPLOYEES.SALARY%TYPE;
    v_bonus            NUMBER := 0;
    v_deduction        NUMBER := 0;
    v_promotion_elig   VARCHAR2(10) := 'NO';

    -- Constants for bonus and deduction limits
    c_max_bonus        CONSTANT NUMBER := 15000;
    c_max_deduction    CONSTANT NUMBER := 7000;

    -- Counter for audit logging
    v_audit_count      NUMBER := 0;

    -- Exception for validation failure
    ex_invalid_action  EXCEPTION;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting salary and promotion management...');

    -- Open the employee cursor
    OPEN emp_cursor;

    LOOP
        FETCH emp_cursor INTO v_employee_id, v_employee_name, v_salary, v_performance, v_hire_date;
        EXIT WHEN emp_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Processing employee: ' || v_employee_name);

        -- 1. Adjust Salary Based on Performance
        IF v_performance = 'A' THEN
            v_bonus := v_salary * 0.10; -- 10% bonus for A rating
            IF v_bonus > c_max_bonus THEN
                v_bonus := c_max_bonus;
            END IF;
            v_new_salary := v_salary + v_bonus;

        ELSIF v_performance = 'B' THEN
            v_bonus := v_salary * 0.05; -- 5% bonus for B rating
            v_new_salary := v_salary + v_bonus;

        ELSIF v_performance = 'C' THEN
            v_deduction := v_salary * 0.02; -- 2% deduction for C rating
            IF v_deduction > c_max_deduction THEN
                v_deduction := c_max_deduction;
            END IF;
            v_new_salary := v_salary - v_deduction;

        ELSE
            RAISE ex_invalid_action;
        END IF;

        -- Update salary in the database
        UPDATE EMPLOYEES
        SET SALARY = v_new_salary
        WHERE EMPLOYEE_ID = v_employee_id;

        -- 2. Check Promotion Eligibility
        IF MONTHS_BETWEEN(SYSDATE, v_hire_date) / 12 >= 5 AND v_performance IN ('A', 'B') THEN
            v_promotion_elig := 'YES';
            DBMS_OUTPUT.PUT_LINE('Employee ' || v_employee_name || ' is eligible for promotion.');
        ELSE
            v_promotion_elig := 'NO';
        END IF;

        -- 3. Log the Operation into Audit Table
        INSERT INTO SALARY_AUDIT (
            AUDIT_ID, EMPLOYEE_ID, OLD_SALARY, NEW_SALARY, BONUS, DEDUCTION, PROMOTION_ELIGIBILITY, ACTION_DATE
        )
        VALUES (
            SALARY_AUDIT_SEQ.NEXTVAL, v_employee_id, v_salary, v_new_salary, v_bonus, v_deduction, v_promotion_elig, SYSDATE
        );

        v_audit_count := v_audit_count + 1;

        DBMS_OUTPUT.PUT_LINE('Salary updated and logged for employee: ' || v_employee_name);

    END LOOP;

    -- Close the cursor
    CLOSE emp_cursor;

    -- Commit transaction
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Salary adjustments and promotions completed.');
    DBMS_OUTPUT.PUT_LINE('Total audit entries: ' || v_audit_count);

EXCEPTION
    WHEN ex_invalid_action THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Invalid performance rating detected. Transaction rolled back.');

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || '. Transaction rolled back.');
END;
/
