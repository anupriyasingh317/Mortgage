CREATE OR REPLACE PROCEDURE PROMOTION_ELIGIBILITY (
    p_employee_id    IN NUMBER,
    p_promotion      OUT VARCHAR2
)
IS
    v_salary       EMPLOYEES.SALARY%TYPE;
    v_hire_date    EMPLOYEES.HIRE_DATE%TYPE;
    v_years        NUMBER;
    v_promotion    VARCHAR2(10) := 'NO';
BEGIN
    -- Fetch employee details
    SELECT SALARY, HIRE_DATE
    INTO v_salary, v_hire_date
    FROM EMPLOYEES
    WHERE EMPLOYEE_ID = p_employee_id;

    -- Calculate years of service
    v_years := TRUNC(MONTHS_BETWEEN(SYSDATE, v_hire_date) / 12);

    -- Determine promotion eligibility
    IF v_years >= 5 AND v_salary < 100000 THEN
        v_promotion := 'YES';
    END IF;

    -- Log promotion eligibility
    INSERT INTO PROMOTION_LOG (
        LOG_ID, EMPLOYEE_ID, ELIGIBILITY, LOG_DATE
    )
    VALUES (
        PROMOTION_LOG_SEQ.NEXTVAL, p_employee_id, v_promotion, SYSDATE
    );

    -- Return promotion eligibility
    p_promotion := v_promotion;
END PROMOTION_ELIGIBILITY;
/
