
-- Recoverable SaaS Decommission
-- Verification assertions for the synthetic test fixture.
-- Expected result: all_checks_passed = 1
-- A value of 0 indicates at least one failed assertion.

SELECT
    CASE
        WHEN
            (
                SELECT COUNT(*)
                FROM information_schema.tables
                WHERE table_schema = DATABASE()
                  AND table_type = 'BASE TABLE'
                  AND table_name IN (
                      'organisations',
                      'users',
                      'activity_logs'
                  )
            ) = 3

            AND (SELECT COUNT(*) FROM organisations) = 3
            AND (SELECT COUNT(*) FROM users) = 5
            AND (SELECT COUNT(*) FROM activity_logs) = 6

            AND (
                SELECT COUNT(*)
                FROM users u
                LEFT JOIN organisations o
                    ON o.id = u.organisation_id
                WHERE o.id IS NULL
            ) = 0

            AND (
                SELECT COUNT(*)
                FROM activity_logs a
                LEFT JOIN users u
                    ON u.id = a.user_id
                WHERE u.id IS NULL
            ) = 0
        THEN 1
        ELSE 0
    END AS all_checks_passed;
