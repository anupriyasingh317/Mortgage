-- File: calculate_credit_limit.sql
CREATE OR REPLACE FUNCTION calculate_credit_limit (
    p_card_type IN VARCHAR2
) RETURN NUMBER IS
    v_credit_limit NUMBER;
BEGIN
    -- Calculate credit limit based on card type
    CASE p_card_type
        WHEN 'DIAMOND' THEN v_credit_limit := 5000;
        WHEN 'PLATINUM' THEN v_credit_limit := 15000;
        WHEN 'PREMIER' THEN v_credit_limit := 25000;
        ELSE
            v_credit_limit := 0;  -- Default to zero if no match
    END CASE;

    RETURN v_credit_limit;
END calculate_credit_limit;
/
