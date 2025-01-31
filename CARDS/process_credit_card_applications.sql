-- File: process_credit_card_applications.sql
CREATE OR REPLACE PROCEDURE process_credit_card_applications (
    p_file_path IN VARCHAR2
) AS
    -- Variables
    v_credit_score   NUMBER;
    v_annual_income  NUMBER;
    v_card_type      VARCHAR2(20);
    v_approval_status VARCHAR2(10);
    v_credit_limit   NUMBER;
    v_application_id NUMBER;
    v_error_message  VARCHAR2(200);

    CURSOR app_cursor IS
        SELECT application_id, card_type, annual_income FROM credit_card_applications WHERE status IS NULL;
    
BEGIN
    -- Read the applications from the CSV
    FOR app_record IN app_cursor LOOP
        BEGIN
            -- Get the credit score via the external API
            v_credit_score := get_credit_score_from_api(app_record.application_id);

            -- Apply rule for credit score
            IF v_credit_score < 500 OR v_credit_score > 850 THEN
                v_error_message := 'Credit score out of range';
                update_application_status(app_record.application_id, 'REJECTED', v_error_message);
                CONTINUE;
            END IF;

            -- Check annual income based on card type
            v_annual_income := app_record.annual_income;
            v_card_type := app_record.card_type;

            -- Call rule checking procedure
            v_approval_status := check_card_rules(v_card_type, v_annual_income);

            -- If rejected based on rules
            IF v_approval_status = 'REJECTED' THEN
                v_error_message := 'Income does not meet card criteria';
                update_application_status(app_record.application_id, 'REJECTED', v_error_message);
                CONTINUE;
            END IF;

            -- Calculate credit limit based on the card type
            v_credit_limit := calculate_credit_limit(v_card_type);

            -- Save approved application details
            update_application_status(app_record.application_id, 'APPROVED', 'Credit limit assigned: ' || v_credit_limit);

            -- Call external third-party service to issue the card
            issue_credit_card(app_record.application_id, v_card_type, v_credit_limit);

        EXCEPTION
            WHEN OTHERS THEN
                v_error_message := SQLERRM;
                update_application_status(app_record.application_id, 'FAILED', v_error_message);
        END;
    END LOOP;
    
END process_credit_card_applications;
/
