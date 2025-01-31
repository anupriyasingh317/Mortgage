-- Creating a package for transaction handling
CREATE OR REPLACE PACKAGE debit_card_pkg AS
    -- Procedure for processing transactions
    PROCEDURE process_transaction(
        p_customer_id        IN NUMBER,
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER
    );

    -- Function to calculate transaction fee
    FUNCTION calculate_fee(
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER
    ) RETURN NUMBER;

    -- Function to validate daily transaction limits
    FUNCTION validate_daily_limit(
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER
    ) RETURN BOOLEAN;

    -- Sub-procedure for logging transaction
    PROCEDURE log_transaction(
        p_customer_id        IN NUMBER,
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER,
        p_fee                IN NUMBER,
        p_status             IN VARCHAR2
    );
END debit_card_pkg;
/

-- Implementing the package body
CREATE OR REPLACE PACKAGE BODY debit_card_pkg AS

    -- Constants
    c_atm_transaction       CONSTANT VARCHAR2(20) := 'ATM';
    c_pos_transaction       CONSTANT VARCHAR2(20) := 'POS';
    c_p2p_transaction       CONSTANT VARCHAR2(20) := 'P2P';
    c_deposit_transaction   CONSTANT VARCHAR2(20) := 'DEPOSIT';

    c_atm_fee               CONSTANT NUMBER := 10;      -- Flat fee for ATM
    c_pos_fee_percentage    CONSTANT NUMBER := 0.01;   -- 1% for POS
    c_p2p_fee_percentage    CONSTANT NUMBER := 0.015;  -- 1.5% for P2P
    c_deposit_fee           CONSTANT NUMBER := 0;      -- No fee for deposit

    c_atm_daily_limit       CONSTANT NUMBER := 50000;
    c_pos_daily_limit       CONSTANT NUMBER := 100000;
    c_p2p_daily_limit       CONSTANT NUMBER := 200000;

    -- Function to calculate transaction fee
    FUNCTION calculate_fee(
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER
    ) RETURN NUMBER IS
        v_fee NUMBER;
    BEGIN
        CASE p_transaction_type
            WHEN c_atm_transaction THEN
                v_fee := c_atm_fee;
            WHEN c_pos_transaction THEN
                v_fee := p_transaction_amount * c_pos_fee_percentage;
            WHEN c_p2p_transaction THEN
                v_fee := p_transaction_amount * c_p2p_fee_percentage;
            WHEN c_deposit_transaction THEN
                v_fee := c_deposit_fee;
            ELSE
                RAISE_APPLICATION_ERROR(-20001, 'Invalid transaction type.');
        END CASE;

        RETURN ROUND(v_fee, 2);
    END calculate_fee;

    -- Function to validate daily transaction limits
    FUNCTION validate_daily_limit(
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER
    ) RETURN BOOLEAN IS
        v_daily_limit NUMBER;
    BEGIN
        CASE p_transaction_type
            WHEN c_atm_transaction THEN
                v_daily_limit := c_atm_daily_limit;
            WHEN c_pos_transaction THEN
                v_daily_limit := c_pos_daily_limit;
            WHEN c_p2p_transaction THEN
                v_daily_limit := c_p2p_daily_limit;
            ELSE
                RETURN TRUE; -- Deposits have no limit
        END CASE;

        IF p_transaction_amount > v_daily_limit THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END validate_daily_limit;

    -- Sub-procedure for logging transaction
    PROCEDURE log_transaction(
        p_customer_id        IN NUMBER,
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER,
        p_fee                IN NUMBER,
        p_status             IN VARCHAR2
    ) IS
    BEGIN
        -- Insert log into a hypothetical TRANSACTION_LOG table
        INSERT INTO transaction_log (
            customer_id, transaction_type, transaction_amount, fee, status, created_at
        ) VALUES (
            p_customer_id, p_transaction_type, p_transaction_amount, p_fee, p_status, SYSDATE
        );

        DBMS_OUTPUT.PUT_LINE('Transaction logged: ' || p_status);
    END log_transaction;

    -- Main procedure for processing transactions
    PROCEDURE process_transaction(
        p_customer_id        IN NUMBER,
        p_transaction_type   IN VARCHAR2,
        p_transaction_amount IN NUMBER
    ) IS
        v_fee         NUMBER;
        v_final_amount NUMBER;
        v_current_balance NUMBER := 100000; -- Assume initial balance
        v_new_balance NUMBER;
        v_status      VARCHAR2(20);
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Processing transaction for Customer ID: ' || p_customer_id);

        -- Calculate transaction fee
        v_fee := calculate_fee(p_transaction_type, p_transaction_amount);

        -- Validate daily limit
        IF NOT validate_daily_limit(p_transaction_type, p_transaction_amount) THEN
            v_status := 'FAILED - LIMIT EXCEEDED';
            log_transaction(p_customer_id, p_transaction_type, p_transaction_amount, v_fee, v_status);
            RAISE_APPLICATION_ERROR(-20002, 'Daily limit exceeded for transaction type: ' || p_transaction_type);
        END IF;

        -- Calculate final amount (amount + fee)
        v_final_amount := p_transaction_amount + v_fee;

        -- Check balance for non-deposit transactions
        IF p_transaction_type != c_deposit_transaction THEN
            IF v_current_balance < v_final_amount THEN
                v_status := 'FAILED - INSUFFICIENT FUNDS';
                log_transaction(p_customer_id, p_transaction_type, p_transaction_amount, v_fee, v_status);
                RAISE_APPLICATION_ERROR(-20003, 'Insufficient funds for transaction.');
            END IF;

            -- Deduct balance
            v_new_balance := v_current_balance - v_final_amount;
        ELSE
            -- Add balance for deposits
            v_new_balance := v_current_balance + p_transaction_amount;
        END IF;

        -- Log success
        v_status := 'SUCCESS';
        log_transaction(p_customer_id, p_transaction_type, p_transaction_amount, v_fee, v_status);

        -- Output transaction details
        DBMS_OUTPUT.PUT_LINE('Transaction Approved for Customer ID: ' || p_customer_id);
        DBMS_OUTPUT.PUT_LINE('Transaction Type: ' || p_transaction_type);
        DBMS_OUTPUT.PUT_LINE('Transaction Amount: ' || p_transaction_amount);
        DBMS_OUTPUT.PUT_LINE('Processing Fee: ' || v_fee);
        DBMS_OUTPUT.PUT_LINE('New Balance: ' || v_new_balance);
    END process_transaction;

END debit_card_pkg;
/

