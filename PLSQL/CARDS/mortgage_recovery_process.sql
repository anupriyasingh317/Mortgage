CREATE OR REPLACE PROCEDURE process_advanced_mortgage_recovery (
    p_mortgage_id IN NUMBER,
    p_mortgage_type IN VARCHAR2,  -- Housing, Business, Property, etc.
    p_principal_amount IN NUMBER,
    p_outstanding_balance IN NUMBER,
    p_interest_rate IN NUMBER,
    p_owner_deceased IN BOOLEAN,  -- True if the mortgage owner has passed away
    p_nominee_id IN NUMBER DEFAULT NULL,
    p_auction_required IN BOOLEAN DEFAULT FALSE,
    p_special_needs_discount IN BOOLEAN DEFAULT FALSE,
    p_waive_off_requested IN BOOLEAN DEFAULT FALSE,
    p_liability_transfer_requested IN BOOLEAN DEFAULT FALSE,
    p_new_nominee_id IN NUMBER DEFAULT NULL,
    p_recovery_amount OUT NUMBER,
    p_recovery_status OUT VARCHAR2
) AS
    -- Local variables
    v_waive_off_limit NUMBER := 0.15;  -- Max waive-off as 15% of outstanding balance
    v_special_needs_discount_rate NUMBER := 0.10;  -- 10% discount for special needs
    v_auction_penalty_rate NUMBER := 0.05;  -- 5% auction penalty
    v_final_recovery_amount NUMBER := 0;
    v_liability_transferred BOOLEAN := FALSE;
    v_nominee_changed BOOLEAN := FALSE;
    v_is_eligible BOOLEAN := TRUE;
    v_recovery_message VARCHAR2(255);
    v_interest_amount NUMBER := 0;
    v_total_payment NUMBER := 0;

    -- Sub-function: Calculate Interest
    FUNCTION calculate_interest (
        p_outstanding_balance IN NUMBER,
        p_interest_rate IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        RETURN p_outstanding_balance * (p_interest_rate / 100);
    END calculate_interest;

    -- Sub-function: Apply Special Needs Discount
    FUNCTION apply_special_needs_discount (
        p_recovery_amount IN NUMBER,
        p_special_needs_discount IN BOOLEAN
    ) RETURN NUMBER IS
    BEGIN
        IF p_special_needs_discount THEN
            RETURN p_recovery_amount * (1 - v_special_needs_discount_rate);
        ELSE
            RETURN p_recovery_amount;
        END IF;
    END apply_special_needs_discount;

    -- Nested Procedure: Handle Waive-off Requests
    PROCEDURE handle_waive_off (
        p_outstanding_balance IN NUMBER,
        p_waive_off_requested IN BOOLEAN
    ) IS
    BEGIN
        IF p_waive_off_requested THEN
            v_final_recovery_amount := p_outstanding_balance * (1 - v_waive_off_limit);
            v_recovery_message := 'Waive-off applied successfully.';
        ELSE
            v_final_recovery_amount := p_outstanding_balance;
        END IF;
    END handle_waive_off;

    -- Nested Procedure: Handle Liability Transfer
    PROCEDURE handle_liability_transfer (
        p_liability_transfer_requested IN BOOLEAN,
        p_new_nominee_id IN NUMBER
    ) IS
    BEGIN
        IF p_liability_transfer_requested THEN
            IF p_new_nominee_id IS NULL THEN
                RAISE_APPLICATION_ERROR(-20001, 'New Nominee ID must be provided for liability transfer.');
            ELSE
                v_liability_transferred := TRUE;
                v_recovery_message := 'Liability successfully transferred to Nominee ID: ' || p_new_nominee_id;
            END IF;
        END IF;
    END handle_liability_transfer;

    -- Nested Procedure: Handle Auction Process
    PROCEDURE handle_auction (
        p_auction_required IN BOOLEAN,
        p_outstanding_balance IN NUMBER
    ) IS
    BEGIN
        IF p_auction_required THEN
            v_final_recovery_amount := p_outstanding_balance * (1 + v_auction_penalty_rate);
            v_recovery_message := 'Auction penalty applied.';
        END IF;
    END handle_auction;

    -- Nested Procedure: Handle Nominee Change
    PROCEDURE handle_nominee_change (
        p_owner_deceased IN BOOLEAN,
        p_nominee_id IN NUMBER,
        p_new_nominee_id IN NUMBER
    ) IS
    BEGIN
        IF p_owner_deceased THEN
            IF p_new_nominee_id IS NULL THEN
                RAISE_APPLICATION_ERROR(-20002, 'Nominee ID is required as the owner is deceased.');
            ELSE
                v_nominee_changed := TRUE;
                v_recovery_message := 'Nominee changed successfully to ID: ' || p_new_nominee_id;
            END IF;
        END IF;
    END handle_nominee_change;

BEGIN
    -- Step 1: Calculate Interest
    v_interest_amount := calculate_interest(p_outstanding_balance, p_interest_rate);

    -- Step 2: Apply Waive-off if requested
    handle_waive_off(p_outstanding_balance, p_waive_off_requested);

    -- Step 3: Apply Special Needs Discount if applicable
    v_final_recovery_amount := apply_special_needs_discount(v_final_recovery_amount, p_special_needs_discount);

    -- Step 4: Handle Liability Transfer if requested
    handle_liability_transfer(p_liability_transfer_requested, p_new_nominee_id);

    -- Step 5: Handle Auction Process if required
    handle_auction(p_auction_required, p_outstanding_balance);

    -- Step 6: Handle Nominee Change if the owner is deceased
    handle_nominee_change(p_owner_deceased, p_nominee_id, p_new_nominee_id);

    -- Step 7: Calculate Total Payment
    v_total_payment := v_final_recovery_amount + v_interest_amount;

    -- Step 8: Update Mortgage Recovery Table
    UPDATE mortgage_recovery
    SET recovery_amount = v_final_recovery_amount,
        total_payment = v_total_payment,
        liability_transferred = v_liability_transferred,
        nominee_changed = v_nominee_changed,
        recovery_status = 'COMPLETED'
    WHERE mortgage_id = p_mortgage_id;

    -- Step 9: Commit the Transaction
    COMMIT;

    -- Output Recovery Status and Amount
    p_recovery_amount := v_final_recovery_amount;
    p_recovery_status := 'SUCCESS';
    DBMS_OUTPUT.PUT_LINE('Recovery completed successfully.');
    DBMS_OUTPUT.PUT_LINE('Final Recovery Amount: ' || v_final_recovery_amount);
    DBMS_OUTPUT.PUT_LINE('Total Payment: ' || v_total_payment);
    DBMS_OUTPUT.PUT_LINE('Recovery Message: ' || v_recovery_message);

EXCEPTION
    WHEN OTHERS THEN
        -- Rollback the transaction in case of any errors
        ROLLBACK;
        p_recovery_status := 'FAILED';
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END process_advanced_mortgage_recovery;
/
