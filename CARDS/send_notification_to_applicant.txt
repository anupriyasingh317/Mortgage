-- File: send_notification_to_applicant.sql
CREATE OR REPLACE PROCEDURE send_notification_to_applicant (
    p_application_id IN NUMBER,
    p_status         IN VARCHAR2
) AS
    v_applicant_email VARCHAR2(100);
BEGIN
    -- Fetch the applicant's email from the database
    SELECT email INTO v_applicant_email
    FROM applicants
    WHERE application_id = p_application_id;

    -- Simulate sending an email notification
    DBMS_OUTPUT.PUT_LINE('Notification sent to ' || v_applicant_email || ' about ' || p_status);
    -- Here, you can replace it with an actual email sending procedure
END send_notification_to_applicant;
/
