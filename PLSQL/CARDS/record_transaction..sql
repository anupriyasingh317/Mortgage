-- -- File: record_transaction.sql
-- CREATE OR REPLACE PROCEDURE record_transaction(
--     p_account_id         IN NUMBER,
--     p_transaction_mode   IN VARCHAR2,
--     p_amount             IN NUMBER,
--     p_fee                IN NUMBER,
--     p_status             IN VARCHAR2
-- ) IS
-- BEGIN
--     -- Simulate inserting the transaction details into a log table
--     INSERT INTO transaction_history (
--         account_id, transaction_mode, transaction_amount, fee, status, transaction_time
--     ) VALUES (
--         p_account_id, p_transaction_mode, p_amount, p_fee, p_status, SYSDATE
--     );

--     DBMS_OUTPUT.PUT_LINE('Transaction recorded successfully: ' || p_status);
-- END record_transaction;
-- /



-- Package Specification
CREATE OR REPLACE PACKAGE transaction_pkg AS
    PROCEDURE record_transaction(
        p_account_id         IN NUMBER,
        p_transaction_mode   IN VARCHAR2,
        p_amount             IN NUMBER,
        p_fee                IN NUMBER,
        p_status             IN VARCHAR2
    );
END transaction_pkg;
/

-- Package Body
CREATE OR REPLACE PACKAGE BODY transaction_pkg AS

    PROCEDURE record_transaction(
        p_account_id         IN NUMBER,
        p_transaction_mode   IN VARCHAR2,
        p_amount             IN NUMBER,
        p_fee                IN NUMBER,
        p_status             IN VARCHAR2
    ) IS
    BEGIN
        -- Simulate inserting the transaction details into a log table
        INSERT INTO transaction_history (
            account_id, transaction_mode, transaction_amount, fee, status, transaction_time
        ) VALUES (
            p_account_id, p_transaction_mode, p_amount, p_fee, p_status, SYSDATE
        );

        DBMS_OUTPUT.PUT_LINE('Transaction recorded successfully: '|| p_status);
    END record_transaction;

END transaction_pkg;
/

-- BEGIN
--     transaction_pkg.record_transaction(1, 'Credit', 1000, 10, 'Success');
-- END;
-- /

