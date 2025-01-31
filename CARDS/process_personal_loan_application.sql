-- File: process_personal_loan_application.sql
CREATE OR REPLACE PROCEDURE process_personal_loan_application (
    p_application_id IN NUMBER,
    p_loan_amount IN NUMBER,
    p_loan_term IN NUMBER,      -- in years
    p_annual_income IN NUMBER,
    p_credit_score IN NUMBER,
    p_interest_rate IN NUMBER,
    p_processing_fee OUT NUMBER,
    p_emi OUT NUMBER,
    p_total_payment OUT NUMBER,
    p_status OUT VARCHAR2,
    p_part_payment IN NUMBER DEFAULT 0,
    p_preclosure_amount IN NUMBER DEFAULT 0,
    p_asset_value IN NUMBER DEFAULT 0
) AS
    -- Declare local variables
    v_processing_fee NUMBER := 0;
    v_emi NUMBER := 0;
    v_total_payment NUMBER := 0;
    v_interest_amount NUMBER := 0;
    v_monthly_interest_rate NUMBER := p_interest_rate / 12 / 100;
    v_monthly_principal NUMBER := 0;
    v_outstanding_principal NUMBER := p_loan_amount;
    v_loan_term_months NUMBER := p_loan_term * 12;
    v_credit_score_threshold NUMBER := 650;
    v_min_income_for_loan NUMBER := 30000;
    v_max_loan_limit NUMBER := 500000;
    v_min_loan_limit NUMBER := 10000;
    v_asset_pledge_threshold NUMBER := 200000; -- Asset pledge threshold for large loans
    v_corporate_discount NUMBER := 0.05;        -- 5% corporate discount
    v_loan_rejection_message VARCHAR2(255);
    
    -- Sub-function 1: Calculate Processing Fee
    FUNCTION calculate_processing_fee (
        p_loan_amount IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        -- Processing Fee logic (Example: 2% of loan amount)
        RETURN p_loan_amount * 0.02;
    END calculate_processing_fee;

    -- Sub-function 2: Calculate EMI
    FUNCTION calculate_emi (
        p_loan_amount IN NUMBER,
        p_interest_rate IN NUMBER,
        p_term_months IN NUMBER
    ) RETURN NUMBER IS
        v_emi NUMBER;
    BEGIN
        -- EMI Formula: EMI = P * r * (1+r)^n / ((1+r)^n - 1)
        v_emi := p_loan_amount * (p_interest_rate / 12 / 100) *
                 POWER(1 + p_interest_rate / 12 / 100, p_term_months) /
                 (POWER(1 + p_interest_rate / 12 / 100, p_term_months) - 1);
        RETURN v_emi;
    END calculate_emi;

    -- Nested Procedure 1: Validate Credit Score
    PROCEDURE validate_credit_score (
        p_credit_score IN NUMBER
    ) IS
    BEGIN
        IF p_credit_score < v_credit_score_threshold THEN
            p_status := 'REJECTED: Low Credit Score';
            RAISE_APPLICATION_ERROR(-20001, 'Credit score is too low.');
        END IF;
    END validate_credit_score;

    -- Nested Procedure 2: Handle Asset Pledge
    PROCEDURE handle_asset_pledge (
        p_asset_value IN NUMBER,
        p_loan_amount IN NUMBER
    ) IS
    BEGIN
        IF p_loan_amount > v_asset_pledge_threshold AND p_asset_value < p_loan_amount * 0.5 THEN
            p_status := 'REJECTED: Insufficient Asset Pledge';
            RAISE_APPLICATION_ERROR(-20002, 'Asset pledge value is insufficient.');
        END IF;
    END handle_asset_pledge;

    -- Nested Procedure 3: Apply Corporate Discount
    PROCEDURE apply_corporate_discount (
        p_annual_income IN NUMBER
    ) IS
    BEGIN
        IF p_annual_income > 500000 THEN
            v_processing_fee := v_processing_fee * (1 - v_corporate_discount);
        END IF;
    END apply_corporate_discount;

BEGIN
    -- Step 1: Validate Credit Score
    validate_credit_score(p_credit_score);

    -- Step 2: Validate Annual Income (Minimum income check for loan eligibility)
    IF p_annual_income < v_min_income_for_loan THEN
        p_status := 'REJECTED: Insufficient Income';
        RAISE_APPLICATION_ERROR(-20003, 'Income is too low for the requested loan amount.');
    END IF;

    -- Step 3: Loan Amount Check (Ensure loan amount is within the allowed limits)
    IF p_loan_amount < v_min_loan_limit OR p_loan_amount > v_max_loan_limit THEN
        p_status := 'REJECTED: Invalid Loan Amount';
        RAISE_APPLICATION_ERROR(-20004, 'Requested loan amount is outside the allowed limits.');
    END IF;

    -- Step 4: Calculate Processing Fee
    v_processing_fee := calculate_processing_fee(p_loan_amount);

    -- Step 5: Apply Corporate Discount if applicable
    apply_corporate_discount(p_annual_income);

    -- Step 6: Handle Asset Pledge if loan amount exceeds threshold
    handle_asset_pledge(p_asset_value, p_loan_amount);

    -- Step 7: Calculate EMI
    v_emi := calculate_emi(p_loan_amount, p_interest_rate, v_loan_term_months);

    -- Step 8: Adjust EMI and Loan Amount based on Part Payment or Preclosure
    IF p_part_payment > 0 THEN
        v_outstanding_principal := v_outstanding_principal - p_part_payment;
        v_emi := calculate_emi(v_outstanding_principal, p_interest_rate, v_loan_term_months);
    END IF;

    IF p_preclosure_amount > 0 THEN
        v_outstanding_principal := v_outstanding_principal - p_preclosure_amount;
        v_emi := calculate_emi(v_outstanding_principal, p_interest_rate, v_loan_term_months);
    END IF;

    -- Step 9: Calculate Total Payment (Loan + Interest + Processing Fee)
    v_interest_amount := v_outstanding_principal * (p_interest_rate / 100);
    v_total_payment := v_outstanding_principal + v_interest_amount + v_processing_fee;

    -- Step 10: Set Loan Status based on conditions
    IF p_status IS NULL THEN
        p_status := 'APPROVED';
    END IF;

    -- Step 11: Log loan details in the database (e.g., insert or update loan record)
    UPDATE personal_loan_applications
    SET loan_amount = p_loan_amount,
        annual_income = p_annual_income,
        credit_score = p_credit_score,
        loan_term = p_loan_term,
        emi = v_emi,
        total_payment = v_total_payment,
        processing_fee = v_processing_fee,
        loan_status = p_status
    WHERE application_id = p_application_id;

    -- Step 12: Commit the transaction
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Rollback the transaction in case of any errors
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        p_status := 'FAILED';
END process_personal_loan_application;
/
