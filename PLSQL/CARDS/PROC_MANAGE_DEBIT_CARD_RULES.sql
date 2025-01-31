SET SERVEROUTPUT ON;

DECLARE
    -- Cursor to fetch eligible customers for debit card rules
    CURSOR cust_cursor IS
        SELECT CUSTOMER_ID, CARD_NUMBER, DAILY_LIMIT, MONTHLY_LIMIT, OVERDRAFT_LIMIT, CURRENT_BALANCE
        FROM DEBIT_CARDS
        WHERE STATUS = 'ACTIVE';

    -- Variables for customer details
    v_customer_id       DEBIT_CARDS.CUSTOMER_ID%TYPE;
    v_card_number       DEBIT_CARDS.CARD_NUMBER%TYPE;
    v_daily_limit       DEBIT_CARDS.DAILY_LIMIT%TYPE;
    v_monthly_limit     DEBIT_CARDS.MONTHLY_LIMIT%TYPE;
    v_overdraft_limit   DEBIT_CARDS.OVERDRAFT_LIMIT%TYPE;
    v_current_balance   DEBIT_CARDS.CURRENT_BALANCE%TYPE;

    -- Transaction details
    v_transaction_id    NUMBER;
    v_transaction_date  DATE := SYSDATE;
    v_transaction_amount NUMBER;
    v_new_balance       NUMBER;

    -- Interest rate and promotion details
    v_interest_rate     NUMBER := 0.18; -- 18% annual rate for overdraft
    v_interest_amount   NUMBER;
    v_cashback          NUMBER := 0;
    v_reward_points     NUMBER := 0;

    -- Constants for promotion eligibility
    c_min_transaction_amount CONSTANT NUMBER := 1000;
    c_cashback_percentage    CONSTANT NUMBER := 0.05; -- 5% cashback
    c_reward_points_rate     CONSTANT NUMBER := 2;    -- 2 points per 100 spent

    -- Counters
    v_transaction_count  NUMBER := 0;
    v_promotion_count    NUMBER := 0;

    -- Exception for overdraft exceeded
    ex_overdraft_exceeded EXCEPTION;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting debit card rule processing...');

    -- Open the cursor
    OPEN cust_cursor;

    LOOP
        FETCH cust_cursor INTO v_customer_id, v_card_number, v_daily_limit, v_monthly_limit, v_overdraft_limit, v_current_balance;
        EXIT WHEN cust_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Processing card: ' || v_card_number);

        -- Simulate transactions for the customer
        FOR i IN 1..5 LOOP -- Simulate 5 transactions
            v_transaction_id := TRANSACTION_SEQ.NEXTVAL;
            v_transaction_amount := ROUND(DBMS_RANDOM.VALUE(500, 5000), 2); -- Random amount between 500 and 5000
            v_transaction_date := SYSDATE + (i / 24); -- Spread transactions across hours

            -- Validate transaction against limits
            IF v_transaction_amount > v_daily_limit THEN
                DBMS_OUTPUT.PUT_LINE('Transaction exceeds daily limit for card: ' || v_card_number);
                CONTINUE;
            ELSIF v_transaction_amount + v_current_balance > v_monthly_limit THEN
                DBMS_OUTPUT.PUT_LINE('Transaction exceeds monthly limit for card: ' || v_card_number);
                CONTINUE;
            END IF;

            -- Check overdraft usage
            IF v_current_balance - v_transaction_amount < 0 THEN
                v_interest_amount := ABS(v_current_balance - v_transaction_amount) * v_interest_rate / 12; -- Monthly interest
                v_new_balance := v_current_balance - v_transaction_amount - v_interest_amount;

                IF ABS(v_new_balance) > v_overdraft_limit THEN
                    RAISE ex_overdraft_exceeded;
                END IF;

                DBMS_OUTPUT.PUT_LINE('Overdraft applied. Interest charged: ' || TO_CHAR(v_interest_amount, '999.99'));
            ELSE
                v_new_balance := v_current_balance - v_transaction_amount;
            END IF;

            -- Update current balance
            v_current_balance := v_new_balance;

            -- Log the transaction
            INSERT INTO TRANSACTION_LOG (
                TRANSACTION_ID, CUSTOMER_ID, CARD_NUMBER, TRANSACTION_DATE, TRANSACTION_AMOUNT, NEW_BALANCE
            )
            VALUES (
                v_transaction_id, v_customer_id, v_card_number, v_transaction_date, v_transaction_amount, v_new_balance
            );

            v_transaction_count := v_transaction_count + 1;

            -- Check promotion eligibility
            IF v_transaction_amount >= c_min_transaction_amount THEN
                v_cashback := v_transaction_amount * c_cashback_percentage;
                v_reward_points := FLOOR(v_transaction_amount / 100) * c_reward_points_rate;

                -- Log promotion
                INSERT INTO PROMOTION_LOG (
                    PROMOTION_ID, CUSTOMER_ID, CARD_NUMBER, TRANSACTION_ID, CASHBACK_AMOUNT, REWARD_POINTS, APPLIED_DATE
                )
                VALUES (
                    PROMOTION_SEQ.NEXTVAL, v_customer_id, v_card_number, v_transaction_id, v_cashback, v_reward_points, SYSDATE
                );

                v_promotion_count := v_promotion_count + 1;

                DBMS_OUTPUT.PUT_LINE('Promotion applied: Cashback = ' || v_cashback || ', Reward Points = ' || v_reward_points);
            END IF;

        END LOOP;
    END LOOP;

    -- Close the cursor
    CLOSE cust_cursor;

    -- Commit transaction
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Processing completed.');
    DBMS_OUTPUT.PUT_LINE('Total transactions logged: ' || v_transaction_count);
    DBMS_OUTPUT.PUT_LINE('Total promotions applied: ' || v_promotion_count);

EXCEPTION
    WHEN ex_overdraft_exceeded THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Overdraft limit exceeded for card: ' || v_card_number);

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || '. Transaction rolled back.');
END;
/
