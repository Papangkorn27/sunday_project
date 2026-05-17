-- =========================================================
-- a. Most popular plan in a policy by companies
-- =========================================================

WITH plan_count AS (
    SELECT
        c.company_name,
        p.policy_id,
        p.effective_date AS policy_effective_date,
        p.expiry_date AS policy_expiry_date,
        pl.plan_code,
        pl.description AS plan_description,
        COUNT(pm.member_id) AS member_count
    FROM silver.policy_member pm
    JOIN silver.policy p
        ON pm.policy_id = p.policy_id
    JOIN silver.company c
        ON p.company_id = c.company_id
    JOIN silver.plan pl
        ON pm.plan_id = pl.plan_id
    GROUP BY
        c.company_name,
        p.policy_id,
        p.effective_date,
        p.expiry_date,
        pl.plan_code,
        pl.description
),
ranked_plan AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY company_name, policy_id
            ORDER BY member_count DESC
        ) AS plan_rank
    FROM plan_count
)
SELECT
    company_name,
    policy_id,
    policy_effective_date,
    policy_expiry_date,
    plan_code,
    plan_description,
    member_count
FROM ranked_plan
WHERE plan_rank = 1
ORDER BY company_name, policy_effective_date;


-- =========================================================
-- b. Number of customers covered by preferred hospital
--     on 1-Feb-2021
-- =========================================================

SELECT
    h.hospital_name AS preferred_hospital,
    COUNT(DISTINCT pm.member_id) AS covered_customer_count
FROM silver.policy_member pm
JOIN silver.hospital h
    ON pm.preferred_hospital_id = h.hospital_id
WHERE DATE '2021-02-01'
      BETWEEN pm.member_effective_date AND pm.member_expiry_date
GROUP BY
    h.hospital_name
ORDER BY
    covered_customer_count DESC,
    h.hospital_name;


-- =========================================================
-- c. How many years each customer has been with us
-- =========================================================

SELECT
    m.member_id,
    m.national_id,
    m.first_name,
    m.last_name,
    MIN(pm.member_effective_date) AS first_covered_date,
    MAX(pm.member_expiry_date) AS last_covered_date,
    ROUND(
        SUM(pm.member_expiry_date - pm.member_effective_date) / 365.25,
        2
    ) AS years_with_us
FROM silver.member m
JOIN silver.policy_member pm
    ON m.member_id = pm.member_id
GROUP BY
    m.member_id,
    m.national_id,
    m.first_name,
    m.last_name
ORDER BY
    years_with_us DESC,
    m.first_name,
    m.last_name;
