-- Main Procedure for Loan Processing
CREATE OR REPLACE PROCEDURE process_loan_application (
    p_loan_id IN NUMBER,
    p_loan_type IN VARCHAR2,              -- Family Tour, Medical, Fixed-Rate Mortgage, etc.
    p_principal_amount IN NUMBER,         -- Loan Principal Amount
    p_interest_rate IN NUMBER,            -- Interest Rate (Annual)
    p_loan_tenure IN NUMBER,              -- Loan Tenure in Years
    p_payment_frequency IN VARCHAR2,      -- Monthly, Quarterly, Annual
    p_balloon_payment IN NUMBER DEFAULT 0,-- Balloon Payment Amount (if applicable)
    p_auto_payment_enabled IN BOOLEAN DEFAULT FALSE,
    p_construction_phase BOOLEAN DEFAULT FALSE, -- Applicable for Construction Mortgages
    p_emi OUT NUMBER,                     -- EMI (Equated Monthly Installment)
    p_total_interest OUT NUMBER,          -- Total Interest Paid Over Loan Tenure
    p_status OUT VARCHAR2                 -- Loan Processing Status
) AS
    -- Variables
    v_emi NUMBER := 0;
    v_total_interest NUMBER := 0;
    v_total_payment NUMBER := 0;
    v_balloon_factor NUMBER := 0;
    v_payment_periods NUMBER := 0;
    v_construction_fee NUMBER := 5000; -- Flat fee for construction loans
    v_is_approved BOOLEAN := TRUE;

    -- Sub-function: EMI Calculation
    FUNCTION calculate_emi (
        p_principal IN NUMBER,
        p_interest_rate IN NUMBER,
        p_tenure_years IN NUMBER,
        p_frequency IN VARCHAR2
    ) RETURN NUMBER IS
        v_rate_per_period NUMBER;
        v_periods NUMBER;
    BEGIN
        -- Determine periods based on frequency
        IF p_frequency = 'Monthly' THEN
            v_periods := p_tenure_years * 12;
            v_rate_per_period := (p_interest_rate / 100) / 12;
        ELSIF p_frequency = 'Quarterly' THEN
            v_periods := p_tenure_years * 4;
            v_rate_per_period := (p_interest_rate / 100) / 4;
        ELSE -- Annual
            v_periods := p_tenure_years;
            v_rate_per_period := (p_interest_rate / 100);
        END IF;

        -- EMI Formula
        RETURN (p_principal * v_rate_per_period * POWER(1 + v_rate_per_period, v_periods)) /
               (POWER(1 + v_rate_per_period, v_periods) - 1);
    END calculate_emi;

    -- Nested Procedure: Process Balloon Loans
    PROCEDURE process_balloon_loan (
        p_balloon_payment IN NUMBER
    ) IS
    BEGIN
        IF p_balloon_payment > 0 THEN
            v_balloon_factor := p_balloon_payment / p_principal_amount;
        END IF;
    END process_balloon_loan;

    -- Nested Procedure: Apply Automatic Payment Discount
    PROCEDURE apply_auto_payment_discount (
        p_auto_payment_enabled IN BOOLEAN,
        p_total_payment IN OUT NUMBER
    ) IS
        v_discount_rate NUMBER := 0.02; -- 2% Discount
    BEGIN
        IF p_auto_payment_enabled THEN
            p_total_payment := p_total_payment * (1 - v_discount_rate);
        END IF;
    END apply_auto_payment_discount;

    -- Nested Procedure: Handle Construction Loans
    PROCEDURE handle_construction_loans (
        p_construction_phase IN BOOLEAN,
        p_principal IN OUT NUMBER
    ) IS
    BEGIN
        IF p_construction_phase THEN
            p_principal := p_principal + v_construction_fee; -- Add construction fee
        END IF;
    END handle_construction_loans;

BEGIN
    -- Step 1: Handle Construction Loans
    handle_construction_loans(p_construction_phase, p_principal_amount);

    -- Step 2: Process Balloon Loans
    process_balloon_loan(p_balloon_payment);

    -- Step 3: Calculate EMI
    v_emi := calculate_emi(p_principal_amount, p_interest_rate, p_loan_tenure, p_payment_frequency);

    -- Step 4: Calculate Total Interest
    v_payment_periods := CASE 
                             WHEN p_payment_frequency = 'Monthly' THEN p_loan_tenure * 12
                             WHEN p_payment_frequency = 'Quarterly' THEN p_loan_tenure * 4
                             ELSE p_loan_tenure
                         END;

    v_total_interest := (v_emi * v_payment_periods) - p_principal_amount;

    -- Step 5: Apply Automatic Payment Discount
    v_total_payment := (v_emi * v_payment_periods) + p_balloon_payment;
    apply_auto_payment_discount(p_auto_payment_enabled, v_total_payment);

    -- Step 6: Set Status Based on Loan Type
    IF p_loan_type = 'Medical' AND v_total_payment > 50000 THEN
        v_is_approved := FALSE; -- Medical loans exceeding $50,000 are not approved
    ELSIF p_loan_type = 'Family Tour' AND v_total_payment > 10000 THEN
        v_is_approved := FALSE; -- Family Tour loans exceeding $10,000 are not approved
    END IF;

    -- Final Decision
    IF v_is_approved THEN
        p_status := 'Approved';
    ELSE
        p_status := 'Rejected';
    END IF;

    -- Output EMI and Total Interest
    p_emi := v_emi;
    p_total_interest := v_total_interest;

    -- Log Details
    DBMS_OUTPUT.PUT_LINE('Loan ID: ' || p_loan_id);
    DBMS_OUTPUT.PUT_LINE('Loan Type: ' || p_loan_type);
    DBMS_OUTPUT.PUT_LINE('EMI: ' || v_emi);
    DBMS_OUTPUT.PUT_LINE('Total Interest: ' || v_total_interest);
    DBMS_OUTPUT.PUT_LINE('Total Payment: ' || v_total_payment);
    DBMS_OUTPUT.PUT_LINE('Status: ' || p_status);

EXCEPTION
    WHEN OTHERS THEN
        -- Handle Errors
        ROLLBACK;
        p_status := 'Error: ' || SQLERRM;
        DBMS_OUTPUT.PUT_LINE('Error Processing Loan: ' || SQLERRM);
END process_loan_application;
/
