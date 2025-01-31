-- File: check_transaction_limit.sql
CREATE OR REPLACE FUNCTION check_transaction_limit(
    p_transaction_mode   IN VARCHAR2,
    p_amount             IN NUMBER
) RETURN BOOLEAN IS
    v_limit NUMBER;
BEGIN
    CASE p_transaction_mode
        WHEN 'ATM' THEN v_limit := 30000;
        WHEN 'POS' THEN v_limit := 75000;
        WHEN 'P2P' THEN v_limit := 100000;
        WHEN 'DEPOSIT' THEN v_limit := 500000;
        ELSE
            RAISE_APPLICATION_ERROR(-20103, 'Invalid transaction mode.');
    END CASE;

    IF p_amount > v_limit THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END check_transaction_limit;
/
