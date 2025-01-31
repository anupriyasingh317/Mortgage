-- File: update_application_status.sql
CREATE OR REPLACE PROCEDURE update_application_status (
    p_application_id IN NUMBER,
    p_status         IN VARCHAR2,
    p_error_message  IN VARCHAR2
) AS
BEGIN
    -- Update the application status in the database
    UPDATE credit_card_applications
    SET status = p_status,
        error_message = p_error_message
    WHERE application_id = p_application_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Application status updated: ' || p_status);
END update_application_status;
/
