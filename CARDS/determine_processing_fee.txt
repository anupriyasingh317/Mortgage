-- File: determine_processing_fee.sql
CREATE OR REPLACE FUNCTION determine_processing_fee(
    p_transaction_mode   IN VARCHAR2,
    p_amount             IN NUMBER
) RETURN NUMBER IS
    v_fee NUMBER;
BEGIN
    CASE p_transaction_mode
        WHEN 'ATM' THEN v_fee := 20; -- Flat fee
        WHEN 'POS' THEN v_fee := p_amount * 0.005; -- 0.5%
        WHEN 'P2P' THEN v_fee := p_amount * 0.0075; -- 0.75%
        WHEN 'DEPOSIT' THEN v_fee := 0; -- No fee for deposits
        ELSE
            RAISE_APPLICATION_ERROR(-20104, 'Invalid transaction mode.');
    END CASE;

    RETURN ROUND(v_fee, 2);
END determine_processing_fee;
/
