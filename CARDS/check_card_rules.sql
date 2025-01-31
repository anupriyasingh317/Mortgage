-- File: check_card_rules.sql
CREATE OR REPLACE FUNCTION check_card_rules (
    p_card_type      IN VARCHAR2,
    p_annual_income  IN NUMBER
) RETURN VARCHAR2 IS
BEGIN
    -- Checking the annual income based on card type
    CASE p_card_type
        WHEN 'DIAMOND' THEN
            IF p_annual_income < 50000 THEN
                RETURN 'REJECTED';
            END IF;
        WHEN 'PLATINUM' THEN
            IF p_annual_income < 100000 THEN
                RETURN 'REJECTED';
            END IF;
        WHEN 'PREMIER' THEN
            IF p_annual_income < 120000 THEN
                RETURN 'REJECTED';
            END IF;
        ELSE
            RETURN 'REJECTED';
    END CASE;

    -- If all checks pass, the application is approved
    RETURN 'APPROVED';
END check_card_rules;
/
