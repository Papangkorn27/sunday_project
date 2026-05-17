CREATE SCHEMA IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.policy_member CASCADE;
DROP TABLE IF EXISTS silver.policy CASCADE;
DROP TABLE IF EXISTS silver.member CASCADE;
DROP TABLE IF EXISTS silver.hospital CASCADE;
DROP TABLE IF EXISTS silver.plan CASCADE;
DROP TABLE IF EXISTS silver.company CASCADE;
DROP TABLE IF EXISTS silver.location CASCADE;

CREATE TABLE silver.location (
    location_id      BIGSERIAL PRIMARY KEY,
    district         VARCHAR(100),
    province         VARCHAR(100) NOT NULL,
    CONSTRAINT uq_location UNIQUE (district, province)
);

CREATE TABLE silver.company (
    company_id       BIGSERIAL PRIMARY KEY,
    company_name     VARCHAR(255) NOT NULL UNIQUE,
    phone_no         VARCHAR(50),
    location_id      BIGINT REFERENCES silver.location(location_id),
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.plan (
    plan_id          BIGSERIAL PRIMARY KEY,
    plan_code        VARCHAR(20) NOT NULL UNIQUE,
    description      TEXT,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.hospital (
    hospital_id      BIGSERIAL PRIMARY KEY,
    hospital_name    VARCHAR(255) NOT NULL UNIQUE,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.member (
    member_id        BIGSERIAL PRIMARY KEY,
    national_id      VARCHAR(50) NOT NULL UNIQUE,
    first_name       VARCHAR(100) NOT NULL,
    last_name        VARCHAR(100) NOT NULL,
    gender           CHAR(1),
    location_id      BIGINT REFERENCES silver.location(location_id),
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_member_gender CHECK (gender IN ('M', 'F') OR gender IS NULL)
);

CREATE TABLE silver.policy (
    policy_id        BIGSERIAL PRIMARY KEY,
    company_id       BIGINT NOT NULL REFERENCES silver.company(company_id),
    policy_no        VARCHAR(100),
    effective_date   DATE NOT NULL,
    expiry_date      DATE NOT NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_policy_dates CHECK (effective_date <= expiry_date),
    CONSTRAINT uq_company_policy_period UNIQUE (company_id, effective_date, expiry_date)
);

CREATE TABLE silver.policy_member (
    policy_member_id BIGSERIAL PRIMARY KEY,
    policy_id        BIGINT NOT NULL REFERENCES silver.policy(policy_id),
    member_id        BIGINT NOT NULL REFERENCES silver.member(member_id),
    plan_id          BIGINT NOT NULL REFERENCES silver.plan(plan_id),
    preferred_hospital_id BIGINT REFERENCES silver.hospital(hospital_id),
    member_effective_date DATE NOT NULL,
    member_expiry_date    DATE NOT NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_policy_member_dates CHECK (member_effective_date <= member_expiry_date),
    CONSTRAINT uq_policy_member UNIQUE (policy_id, member_id)
);