-- File: issue_credit_card.sql
CREATE OR REPLACE PROCEDURE issue_credit_card (
    p_application_id IN NUMBER,
    p_card_type      IN VARCHAR2,
    p_credit_limit   IN NUMBER
) AS
BEGIN
    -- Call external third-party service to issue the card
    -- Simulate a call to the card issuance system
    INSERT INTO issued_cards (application_id, card_type, credit_limit, issue_date)
    VALUES (p_application_id, p_card_type, p_credit_limit, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Card issued successfully for Application ID: ' || p_application_id);
END issue_credit_card;
/
