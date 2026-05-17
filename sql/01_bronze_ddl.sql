CREATE SCHEMA IF NOT EXISTS bronze;

DROP TABLE IF EXISTS bronze.company_list CASCADE;
CREATE TABLE bronze.company_list (
    company_name      VARCHAR(255) NOT NULL,
    district          VARCHAR(100),
    province          VARCHAR(100),
    phone_no          VARCHAR(50),
    effective_date    DATE NOT NULL,
    expiry_date       DATE NOT NULL,
    loaded_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS bronze.plan_list CASCADE;
CREATE TABLE bronze.plan_list (
    plan_code         VARCHAR(20) PRIMARY KEY,
    description       TEXT,
    loaded_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS bronze.customer_list CASCADE;
CREATE TABLE bronze.customer_list (
    name               VARCHAR(255) NOT NULL,
    first_name         VARCHAR(100) NOT NULL,
    last_name          VARCHAR(100) NOT NULL,
    national_id        VARCHAR(50) NOT NULL,
    plan_code          VARCHAR(20) NOT NULL,
    gender             CHAR(1),
    district           VARCHAR(100),
    province           VARCHAR(100),
    preferred_hospital VARCHAR(255),
    loaded_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS bronze.employee_addition CASCADE;
CREATE TABLE bronze.employee_addition (
    name               VARCHAR(255) NOT NULL,
    first_name         VARCHAR(100) NOT NULL,
    last_name          VARCHAR(100) NOT NULL,
    national_id        VARCHAR(50) NOT NULL,
    plan_code          VARCHAR(20) NOT NULL,
    gender             CHAR(1),
    district           VARCHAR(100),
    province           VARCHAR(100),
    preferred_hospital VARCHAR(255),
    effective_date     DATE NOT NULL,
    loaded_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);