-- File: validate_account_status.sql
CREATE OR REPLACE FUNCTION validate_account_status(p_account_id IN NUMBER) RETURN BOOLEAN IS
    v_account_status VARCHAR2(20);
BEGIN
    -- Simulate an account status check from the accounts table
    SELECT account_status INTO v_account_status FROM accounts WHERE account_id = p_account_id;

    IF v_account_status = 'ACTIVE' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END validate_account_status;
/
