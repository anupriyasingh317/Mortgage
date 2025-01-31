-- File: manage_card_transactions.sql
CREATE OR REPLACE PROCEDURE manage_card_transactions(
    p_account_id         IN NUMBER,
    p_transaction_mode   IN VARCHAR2,
    p_amount             IN NUMBER
) AS
    v_processing_fee     NUMBER;
    v_is_valid_account   BOOLEAN;
    v_limit_status       BOOLEAN;
    v_updated_balance    NUMBER := 200000; -- Assume starting balance
    v_status             VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Processing transaction for Account ID: ' || p_account_id);

    -- Validate account
    v_is_valid_account := validate_account_status(p_account_id);
    IF NOT v_is_valid_account THEN
        v_status := 'FAILURE - ACCOUNT INACTIVE';
        record_transaction(p_account_id, p_transaction_mode, p_amount, 0, v_status);
        RAISE_APPLICATION_ERROR(-20100, 'Account is inactive or blocked.');
    END IF;

    -- Check transaction limit
    v_limit_status := check_transaction_limit(p_transaction_mode, p_amount);
    IF NOT v_limit_status THEN
        v_status := 'FAILURE - EXCEEDS LIMIT';
        record_transaction(p_account_id, p_transaction_mode, p_amount, 0, v_status);
        RAISE_APPLICATION_ERROR(-20101, 'Transaction exceeds allowable limit.');
    END IF;

    -- Calculate processing fee
    v_processing_fee := determine_processing_fee(p_transaction_mode, p_amount);

    -- Validate sufficient balance for non-deposit transactions
    IF p_transaction_mode != 'DEPOSIT' THEN
        IF v_updated_balance < (p_amount + v_processing_fee) THEN
            v_status := 'FAILURE - INSUFFICIENT FUNDS';
            record_transaction(p_account_id, p_transaction_mode, p_amount, v_processing_fee, v_status);
            RAISE_APPLICATION_ERROR(-20102, 'Insufficient funds for the transaction.');
        END IF;
        v_updated_balance := v_updated_balance - (p_amount + v_processing_fee);
    ELSE
        -- Update balance for deposit transactions
        v_updated_balance := v_updated_balance + p_amount;
    END IF;

    -- Log success
    v_status := 'SUCCESS';
    record_transaction(p_account_id, p_transaction_mode, p_amount, v_processing_fee, v_status);

    DBMS_OUTPUT.PUT_LINE('Transaction completed. Updated balance: ' || v_updated_balance);
END manage_card_transactions;
/
