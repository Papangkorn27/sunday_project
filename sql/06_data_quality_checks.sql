DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM bronze.company_list
        WHERE effective_date > expiry_date
    ) THEN
        RAISE EXCEPTION 'Data quality failed: policy effective_date is after expiry_date.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM bronze.company_list
        WHERE NULLIF(TRIM(company_name), '') IS NULL
    ) THEN
        RAISE EXCEPTION 'Data quality failed: company_name must not be null or blank.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM bronze.customer_list
        WHERE NULLIF(TRIM(national_id), '') IS NULL
        UNION ALL
        SELECT 1
        FROM bronze.employee_addition
        WHERE NULLIF(TRIM(national_id), '') IS NULL
    ) THEN
        RAISE EXCEPTION 'Data quality failed: member national_id must not be null or blank.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM bronze.customer_list
        WHERE NULLIF(UPPER(TRIM(gender)), '') NOT IN ('M', 'F')
        UNION ALL
        SELECT 1
        FROM bronze.employee_addition
        WHERE NULLIF(UPPER(TRIM(gender)), '') NOT IN ('M', 'F')
    ) THEN
        RAISE EXCEPTION 'Data quality failed: gender must be M, F, or null.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM bronze.customer_list c
        LEFT JOIN bronze.plan_list p
            ON TRIM(p.plan_code) = TRIM(c.plan_code)
        WHERE p.plan_code IS NULL
        UNION ALL
        SELECT 1
        FROM bronze.employee_addition e
        LEFT JOIN bronze.plan_list p
            ON TRIM(p.plan_code) = TRIM(e.plan_code)
        WHERE p.plan_code IS NULL
    ) THEN
        RAISE EXCEPTION 'Data quality failed: source plan_code must exist in bronze.plan_list.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM silver.policy_member pm
        JOIN silver.policy p
            ON p.policy_id = pm.policy_id
        WHERE pm.member_effective_date > pm.member_expiry_date
           OR pm.member_effective_date < p.effective_date
           OR pm.member_expiry_date <> p.expiry_date
    ) THEN
        RAISE EXCEPTION 'Data quality failed: member coverage dates must be valid and expire with the policy.';
    END IF;

    IF EXISTS (
        SELECT policy_id, member_id
        FROM silver.policy_member
        GROUP BY policy_id, member_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Data quality failed: duplicate policy-member records found.';
    END IF;
END
$$;
