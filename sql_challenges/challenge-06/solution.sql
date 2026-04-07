CREATE TABLE product (
    product_id NUMBER(10),
    product_name VARCHAR2(30),
    package_id NUMBER(10),
    current_inventory_count NUMBER(5),
    store_cost NUMBER(10,2),
    sale_price NUMBER(10,2),
    last_update_date DATE,
    updated_by_user VARCHAR2(30),
    pet_flag VARCHAR2(1),
    CONSTRAINT pk_product PRIMARY KEY (product_id)
);

CREATE TABLE pet_care_log (
    product_id NUMBER(10),
    log_datetime DATE,
    log_text VARCHAR2(500),
    update_date DATE,
    updated_by_user VARCHAR2(30),
    CONSTRAINT pk_pet_care_log PRIMARY KEY (product_id, log_datetime),
    CONSTRAINT fk_pet_care_log_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
);

CREATE OR REPLACE TRIGGER trg_pet_care_log_bi
BEFORE INSERT ON pet_care_log
FOR EACH ROW
BEGIN
    :NEW.update_date := SYSDATE;
    :NEW.updated_by_user := USER;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Insert error in PET_CARE_LOG: ' || SQLERRM
        );
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_bu
BEFORE UPDATE ON pet_care_log
FOR EACH ROW
BEGIN
    IF USER = :OLD.updated_by_user THEN
        :NEW.update_date := SYSDATE;
        :NEW.updated_by_user := USER;
    ELSE
        RAISE_APPLICATION_ERROR(
            -20002,
            'Update not allowed: only the creator can update this row.'
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(
                -20003,
                'Update error in PET_CARE_LOG: ' || SQLERRM
            );
        END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_bd
BEFORE DELETE ON pet_care_log
FOR EACH ROW
BEGIN
    IF USER <> 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Delete not allowed: only JOEMANAGER can delete rows.'
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20004 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(
                -20005,
                'Delete error in PET_CARE_LOG: ' || SQLERRM
            );
        END IF;
END;
/

INSERT INTO product (
    product_id,
    product_name,
    package_id,
    current_inventory_count,
    store_cost,
    sale_price,
    last_update_date,
    updated_by_user,
    pet_flag
) VALUES (
    1,
    'Dog Food',
    NULL,
    20,
    10.00,
    15.00,
    SYSDATE,
    USER,
    'Y'
);

INSERT INTO pet_care_log (
    product_id,
    log_datetime,
    log_text
) VALUES (
    1,
    SYSDATE,
    'Feed twice a day'
);

SELECT * FROM pet_care_log;

UPDATE pet_care_log
SET log_text = 'Feed three times a day'
WHERE product_id = 1;

SELECT * FROM pet_care_log;

DELETE FROM pet_care_log
WHERE product_id = 1;