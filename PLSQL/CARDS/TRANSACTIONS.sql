SET SERVEROUTPUT ON;

DECLARE
    -- Transaction Types
    c_atm_transaction       CONSTANT VARCHAR2(20) := 'ATM';
    c_pos_transaction       CONSTANT VARCHAR2(20) := 'POS';
    c_p2p_transaction       CONSTANT VARCHAR2(20) := 'P2P';
    c_deposit_transaction   CONSTANT VARCHAR2(20) := 'DEPOSIT';

    -- Transaction Fee Constants
    c_atm_fee               CONSTANT NUMBER := 10; -- Flat fee for ATM
    c_pos_fee_percentage    CONSTANT NUMBER := 0.01; -- 1% fee for POS
    c_p2p_fee_percentage    CONSTANT NUMBER := 0.015; -- 1.5% fee for P2P
    c_deposit_fee           CONSTANT NUMBER := 0; -- No fee for deposit

    -- Limits
    c_atm_daily_limit       CONSTANT NUMBER := 50000;
    c_pos_daily_limit       CONSTANT NUMBER := 100000;
    c_p2p_daily_limit       CONSTANT NUMBER := 200000;
    c_atm_per_transaction   CONSTANT NUMBER := 20000;

    -- Transaction Variables
    v_customer_id           NUMBER;
    v_transaction_type      VARCHAR2(20);
    v_transaction_amount    NUMBER;
    v_transaction_fee       NUMBER;
    v_final_amount          NUMBER;
    v_daily_limit           NUMBER;
    v_processing_fee        NUMBER;

    -- Balances
    v_current_balance       NUMBER := 100000; -- Assume initial balance
    v_new_balance           NUMBER;

    -- Counters
    v_transaction_count     NUMBER := 0;

    -- Error Handling
    ex_limit_exceeded       EXCEPTION;
    ex_insufficient_funds   EXCEPTION;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Starting Complex Transaction Processing ---');

    -- Simulate transactions with a loop
    FOR i IN 1..20 LOOP
        -- Randomly assign transaction details
        v_customer_id := 100 + i;
        v_transaction_type := CASE MOD(i, 4)
                                  WHEN 0 THEN c_atm_transaction
                                  WHEN 1 THEN c_pos_transaction
                                  WHEN 2 THEN c_p2p_transaction
                                  ELSE c_deposit_transaction
                              END;
        v_transaction_amount := ROUND(DBMS_RANDOM.VALUE(500, 50000), 2);

        DBMS_OUTPUT.PUT_LINE('Processing Transaction #' || i || ' for Customer ID: ' || v_customer_id);
        DBMS_OUTPUT.PUT_LINE('Transaction Type: ' || v_transaction_type || ', Amount: ' || v_transaction_amount);

        -- Determine transaction fee and limit based on type
        CASE v_transaction_type
            WHEN c_atm_transaction THEN
                v_transaction_fee := c_atm_fee;
                v_daily_limit := c_atm_daily_limit;

                -- Check ATM per-transaction limit
                IF v_transaction_amount > c_atm_per_transaction THEN
                    RAISE_APPLICATION_ERROR(-20001, 'ATM transaction amount exceeds per-transaction limit.');
                END IF;

            WHEN c_pos_transaction THEN
                v_transaction_fee := v_transaction_amount * c_pos_fee_percentage;
                v_daily_limit := c_pos_daily_limit;

            WHEN c_p2p_transaction THEN
                v_transaction_fee := v_transaction_amount * c_p2p_fee_percentage;
                v_daily_limit := c_p2p_daily_limit;

            WHEN c_deposit_transaction THEN
                v_transaction_fee := c_deposit_fee;
                v_daily_limit := NULL; -- No limit for deposits

            ELSE
                RAISE_APPLICATION_ERROR(-20002, 'Invalid transaction type.');
        END CASE;

        -- Calculate final amount with fees
        v_processing_fee := ROUND(v_transaction_fee, 2);
        v_final_amount := v_transaction_amount + v_processing_fee;

        DBMS_OUTPUT.PUT_LINE('Processing Fee: ' || v_processing_fee);

        -- Validate limits
        IF v_transaction_type != c_deposit_transaction THEN
            IF v_transaction_amount > v_daily_limit THEN
                RAISE ex_limit_exceeded;
            END IF;

            -- Check balance
            IF v_current_balance < v_final_amount THEN
                RAISE ex_insufficient_funds;
            END IF;

            -- Deduct from balance
            v_new_balance := v_current_balance - v_final_amount;
        ELSE
            -- Deposit: Add to balance
            v_new_balance := v_current_balance + v_transaction_amount;
        END IF;

        -- Log Transaction
        DBMS_OUTPUT.PUT_LINE('Transaction Approved.');
        DBMS_OUTPUT.PUT_LINE('Customer ID: ' || v_customer_id || ', Type: ' || v_transaction_type);
        DBMS_OUTPUT.PUT_LINE('Transaction Amount: ' || v_transaction_amount || ', Fee: ' || v_processing_fee);
        DBMS_OUTPUT.PUT_LINE('New Balance: ' || v_new_balance);

        -- Update balance for next iteration
        v_current_balance := v_new_balance;

        -- Increment transaction count
        v_transaction_count := v_transaction_count + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('--- Transaction Processing Completed ---');
    DBMS_OUTPUT.PUT_LINE('Total Transactions Processed: ' || v_transaction_count);

EXCEPTION
    WHEN ex_limit_exceeded THEN
        DBMS_OUTPUT.PUT_LINE('Error: Transaction exceeds daily limit.');
    WHEN ex_insufficient_funds THEN
        DBMS_OUTPUT.PUT_LINE('Error: Insufficient funds for transaction.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || '. Transaction failed.');
END;
/
