BEGIN;

INSERT INTO silver.plan (plan_code, description)
SELECT
    TRIM(plan_code) AS plan_code,
    NULLIF(TRIM(description), '') AS description
FROM bronze.plan_list
ON CONFLICT (plan_code) DO UPDATE
SET
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

WITH raw_locations AS (
    SELECT district, province FROM bronze.company_list
    UNION
    SELECT district, province FROM bronze.customer_list
    UNION
    SELECT district, province FROM bronze.employee_addition
),
normalized AS (
    SELECT DISTINCT
        NULLIF(TRIM(district), '') AS district,
        CASE
            WHEN UPPER(TRIM(province)) = 'BKK' THEN 'Bangkok'
            ELSE NULLIF(TRIM(province), '')
        END AS province
    FROM raw_locations
    WHERE NULLIF(TRIM(province), '') IS NOT NULL
)
INSERT INTO silver.location (district, province)
SELECT district, province
FROM normalized
ON CONFLICT (district, province) DO NOTHING;

WITH hospitals AS (
    SELECT preferred_hospital FROM bronze.customer_list
    UNION
    SELECT preferred_hospital FROM bronze.employee_addition
)
INSERT INTO silver.hospital (hospital_name)
SELECT DISTINCT NULLIF(TRIM(preferred_hospital), '') AS hospital_name
FROM hospitals
WHERE NULLIF(TRIM(preferred_hospital), '') IS NOT NULL
ON CONFLICT (hospital_name) DO NOTHING;

WITH company_source AS (
    SELECT
        TRIM(company_name) AS company_name,
        NULLIF(TRIM(phone_no), '') AS phone_no,
        NULLIF(TRIM(district), '') AS district,
        CASE
            WHEN UPPER(TRIM(province)) = 'BKK' THEN 'Bangkok'
            ELSE NULLIF(TRIM(province), '')
        END AS province
    FROM bronze.company_list
)
INSERT INTO silver.company (company_name, phone_no, location_id)
SELECT
    cs.company_name,
    cs.phone_no,
    l.location_id
FROM company_source cs
LEFT JOIN silver.location l
    ON l.district IS NOT DISTINCT FROM cs.district
   AND l.province = cs.province
ON CONFLICT (company_name) DO UPDATE
SET
    phone_no = EXCLUDED.phone_no,
    location_id = EXCLUDED.location_id,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO silver.policy (company_id, policy_no, effective_date, expiry_date)
SELECT
    c.company_id,
    CONCAT('POL-', c.company_id, '-', TO_CHAR(cl.effective_date, 'YYYYMMDD')) AS policy_no,
    cl.effective_date,
    cl.expiry_date
FROM bronze.company_list cl
JOIN silver.company c
    ON c.company_name = TRIM(cl.company_name)
ON CONFLICT (company_id, effective_date, expiry_date) DO UPDATE
SET
    policy_no = EXCLUDED.policy_no,
    updated_at = CURRENT_TIMESTAMP;

WITH member_source AS (
    SELECT
        1 AS source_priority,
        TRIM(national_id) AS national_id,
        TRIM(first_name) AS first_name,
        TRIM(last_name) AS last_name,
        NULLIF(UPPER(TRIM(gender)), '') AS gender,
        NULLIF(TRIM(district), '') AS district,
        CASE
            WHEN UPPER(TRIM(province)) = 'BKK' THEN 'Bangkok'
            ELSE NULLIF(TRIM(province), '')
        END AS province
    FROM bronze.customer_list
    UNION ALL
    SELECT
        2 AS source_priority,
        TRIM(national_id) AS national_id,
        TRIM(first_name) AS first_name,
        TRIM(last_name) AS last_name,
        NULLIF(UPPER(TRIM(gender)), '') AS gender,
        NULLIF(TRIM(district), '') AS district,
        CASE
            WHEN UPPER(TRIM(province)) = 'BKK' THEN 'Bangkok'
            ELSE NULLIF(TRIM(province), '')
        END AS province
    FROM bronze.employee_addition
),
deduped AS (
    SELECT DISTINCT ON (national_id)
        national_id,
        first_name,
        last_name,
        gender,
        district,
        province
    FROM member_source
    WHERE national_id IS NOT NULL
    ORDER BY national_id, source_priority
)
INSERT INTO silver.member (national_id, first_name, last_name, gender, location_id)
SELECT
    d.national_id,
    d.first_name,
    d.last_name,
    d.gender,
    l.location_id
FROM deduped d
LEFT JOIN silver.location l
    ON l.district IS NOT DISTINCT FROM d.district
   AND l.province = d.province
ON CONFLICT (national_id) DO UPDATE
SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    gender = EXCLUDED.gender,
    location_id = EXCLUDED.location_id,
    updated_at = CURRENT_TIMESTAMP;

WITH coverage_source AS (
    SELECT
        TRIM(cl.name) AS company_name,
        TRIM(cl.national_id) AS national_id,
        TRIM(cl.plan_code) AS plan_code,
        NULLIF(TRIM(cl.preferred_hospital), '') AS preferred_hospital,
        co.effective_date AS member_effective_date,
        co.expiry_date AS member_expiry_date
    FROM bronze.customer_list cl
    JOIN bronze.company_list co
        ON TRIM(co.company_name) = TRIM(cl.name)
    UNION ALL
    SELECT
        TRIM(ea.name) AS company_name,
        TRIM(ea.national_id) AS national_id,
        TRIM(ea.plan_code) AS plan_code,
        NULLIF(TRIM(ea.preferred_hospital), '') AS preferred_hospital,
        ea.effective_date AS member_effective_date,
        co.expiry_date AS member_expiry_date
    FROM bronze.employee_addition ea
    JOIN bronze.company_list co
        ON TRIM(co.company_name) = TRIM(ea.name)
)
INSERT INTO silver.policy_member (
    policy_id,
    member_id,
    plan_id,
    preferred_hospital_id,
    member_effective_date,
    member_expiry_date
)
SELECT
    p.policy_id,
    m.member_id,
    pl.plan_id,
    h.hospital_id,
    cs.member_effective_date,
    cs.member_expiry_date
FROM coverage_source cs
JOIN silver.company c
    ON c.company_name = cs.company_name
JOIN silver.policy p
    ON p.company_id = c.company_id
   AND cs.member_effective_date BETWEEN p.effective_date AND p.expiry_date
JOIN silver.member m
    ON m.national_id = cs.national_id
JOIN silver.plan pl
    ON pl.plan_code = cs.plan_code
LEFT JOIN silver.hospital h
    ON h.hospital_name = cs.preferred_hospital
ON CONFLICT (policy_id, member_id) DO UPDATE
SET
    plan_id = EXCLUDED.plan_id,
    preferred_hospital_id = EXCLUDED.preferred_hospital_id,
    member_effective_date = EXCLUDED.member_effective_date,
    member_expiry_date = EXCLUDED.member_expiry_date,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;
