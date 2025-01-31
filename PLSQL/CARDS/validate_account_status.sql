-- File: validate_account_status.sql
CREATE OR REPLACE FUNCTION validate_account_status(p_account_id IN NUMBER) RETURN BOOLEAN IS
    v_account_status VARCHAR2(20);
BEGIN
    -- Simulate an account status check from the accounts table
    SELECT account_status INTO v_account_status FROM accounts WHERE account_id = p_account_id;
    IF v_account_status = 'ACTIVE' THEN
        issue_credit_card(123, 'debit', 10000);
        RETURN TRUE;
    ELSE
        transaction_pkg.record_transaction(1, 'Credit', 1000, 10, 'Success');
        RETURN FALSE;
    END IF;
END validate_account_status;
/
