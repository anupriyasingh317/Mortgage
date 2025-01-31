-- File: process_home_loan_application.sql
CREATE OR REPLACE PROCEDURE process_home_loan_application_with_additional_logic (
    p_application_id IN NUMBER,
    p_loan_amount IN NUMBER,
    p_loan_term IN NUMBER,      -- in years
    p_loan_type IN VARCHAR2,    -- e.g., 'HOME', 'PERSONAL'
    p_interest_rate IN NUMBER,
    p_annual_income IN NUMBER,
    p_credit_score IN NUMBER,
    p_jewelry_value IN NUMBER DEFAULT 0,
    p_fd_value IN NUMBER DEFAULT 0,
    p_part_payment IN NUMBER DEFAULT 0,
    p_preclosure_amount IN NUMBER DEFAULT 0,
    p_processing_fee OUT NUMBER,
    p_emi OUT NUMBER,
    p_total_payment OUT NUMBER,
    p_status OUT VARCHAR2
) AS
    v_total_interest NUMBER := 0;
    v_monthly_interest NUMBER;
    v_monthly_principal NUMBER;
    v_outstanding_principal NUMBER := p_loan_amount;
    v_processing_fee NUMBER := 0;
    v_corporate_discount NUMBER := 0;
    v_emi_reduction NUMBER := 0;
    v_emi_adjusted NUMBER := 0;
    v_total_paid NUMBER := 0;
    v_interest_amount NUMBER := 0;
    v_total_reduction NUMBER := 0;
    v_final_balance NUMBER := 0;
    v_loan_term_months NUMBER;
    v_credit_score_limit NUMBER := 600;
    v_jewelry_required NUMBER := 100000;  -- For loans above this amount, jewelry collateral is required
    v_asset_pledge_threshold NUMBER := 200000; -- Asset pledge required if loan > 2 Lakhs
    
    CURSOR loan_cursor IS
        SELECT * FROM home_loan_applications WHERE application_id = p_application_id;

    -- Sub-function 1: Calculate processing fee
    FUNCTION calculate_processing_fee (
        p_loan_amount IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        -- Processing Fee Logic (Example: 1% of loan amount)
        RETURN p_loan_amount * 0.01;
    END calculate_processing_fee;

    -- Sub-function 2: Calculate EMI
    FUNCTION calculate_emi (
        p_loan_amount IN NUMBER,
        p_interest_rate IN NUMBER,
        p_term_months IN NUMBER
    ) RETURN NUMBER IS
        v_emi NUMBER;
        v_monthly_interest_rate NUMBER := p_interest_rate / 12 / 100;
    BEGIN
        -- Formula for EMI: EMI = P * r * (1+r)^n / ((1+r)^n - 1)
        v_emi := p_loan_amount * v_monthly_interest_rate *
                 POWER(1 + v_monthly_interest_rate, p_term_months) /
                 (POWER(1 + v_monthly_interest_rate, p_term_months) - 1);
        RETURN v_emi;
    END calculate_emi;

    -- Nested Procedure 1: Validate Credit Score
    PROCEDURE validate_credit_score (
        p_credit_score IN NUMBER
    ) IS
    BEGIN
        IF p_credit_score < v_credit_score_limit THEN
            p_status := 'REJECTED: Poor Credit Score';
            RETURN;
        END IF;
    END validate_credit_score;

    -- Nested Procedure 2: Handle Jewelry Collateral
    PROCEDURE handle_jewelry_collateral (
        p_jewelry_value IN NUMBER,
        p_loan_amount IN NUMBER
    ) IS
    BEGIN
        IF p_jewelry_value < v_jewelry_required AND p_loan_amount > v_jewelry_required THEN
            p_status := 'REJECTED: Insufficient Jewelry Collateral';
            RETURN;
        END IF;
    END handle_jewelry_collateral;

    -- Nested Procedure 3: Handle Fixed Deposit (FD) Loans
    PROCEDURE handle_fd_loan (
        p_fd_value IN NUMBER,
        p_loan_amount IN NUMBER
    ) IS
    BEGIN
        IF p_fd_value < (p_loan_amount * 0.5) THEN
            p_status := 'REJECTED: Insufficient FD for Loan';
            RETURN;
        END IF;
    END handle_fd_loan;

BEGIN
    -- Fetch loan application details
    FOR loan_rec IN loan_cursor LOOP
        BEGIN
            -- Validate Credit Score
            validate_credit_score(p_credit_score);

            -- Handle Jewelry Collateral if applicable
            handle_jewelry_collateral(p_jewelry_value, p_loan_amount);

            -- Handle FD loan if applicable
            handle_fd_loan(p_fd_value, p_loan_amount);

            -- Calculate Processing Fee
            v_processing_fee := calculate_processing_fee(p_loan_amount);

            -- Apply Corporate Discount if applicable
            IF loan_rec.loan_type = 'HOME' AND p_annual_income > 1000000 THEN
                v_corporate_discount := 0.02;  -- 2% corporate discount
                v_processing_fee := v_processing_fee * (1 - v_corporate_discount);
            END IF;

            -- Calculate EMI based on loan amount, interest rate, and term
            v_loan_term_months := p_loan_term * 12;
            v_emi := calculate_emi(p_loan_amount, p_interest_rate, v_loan_term_months);
            p_processing_fee := v_processing_fee;

            -- Calculate interest and principal breakdown
            v_interest_amount := p_loan_amount * (p_interest_rate / 100);
            v_total_payment := p_loan_amount + v_interest_amount;

            -- Apply Preclosure if applicable
            IF p_preclosure_amount > 0 THEN
                -- Adjust EMI if preclosure amount is provided
                v_total_paid := p_loan_amount - p_preclosure_amount;
                v_emi_adjusted := calculate_emi(v_total_paid, p_interest_rate, v_loan_term_months);
                v_final_balance := v_total_paid;
            ELSE
                v_total_paid := p_loan_amount;
                v_emi_adjusted := v_emi;
                v_final_balance := p_loan_amount;
            END IF;

            -- Part Payment logic (Adjust Principal and EMI)
            IF p_part_payment > 0 THEN
                v_outstanding_principal := v_outstanding_principal - p_part_payment;
                v_emi_reduction := calculate_emi(v_outstanding_principal, p_interest_rate, v_loan_term_months);
                v_total_reduction := v_emi - v_emi_reduction;
                v_final_balance := v_outstanding_principal;
                v_emi_adjusted := v_emi_reduction;
            END IF;

            -- Calculate Final Payment including processing fee, EMI, and any adjustments
            p_total_payment := v_final_balance + v_processing_fee;

            -- Store Loan Status: Approved, Rejected, or Pending
            IF p_status IS NULL THEN
                IF v_total_payment < p_loan_amount THEN
                    p_status := 'REJECTED: Insufficient payment';
                ELSE
                    p_status := 'APPROVED';
                END IF;
            END IF;

            -- Log results to database (For example, insert or update loan status)
            UPDATE home_loan_applications
            SET emi = v_emi_adjusted,
                total_payment = p_total_payment,
                processing_fee = v_processing_fee,
                loan_status = p_status
            WHERE application_id = p_application_id;

            COMMIT;

        EXCEPTION
            WHEN OTHERS THEN
                p_status := 'FAILED';
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        END;
    END LOOP;

END process_home_loan_application_with_additional_logic;
/
