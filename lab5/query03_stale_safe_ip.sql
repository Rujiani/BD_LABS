WITH active_safe AS (
    SELECT safe_ip_id, user_id, ip_address, added_at
    FROM ws_safe_ip
    WHERE is_active = TRUE
),
login_on_safe AS (
    SELECT
        s.safe_ip_id,
        s.user_id,
        s.ip_address,
        s.added_at AS safe_ip_added_at,
        MAX(lh.logged_at) AS last_login_at,
        COUNT(lh.login_id) AS login_count
    FROM active_safe s
    LEFT JOIN ws_login_history lh
        ON lh.user_id = s.user_id
       AND lh.ip_address = s.ip_address
    GROUP BY s.safe_ip_id, s.user_id, s.ip_address, s.added_at
),
last_other AS (
    SELECT DISTINCT ON (s.safe_ip_id)
        s.safe_ip_id,
        lh.ip_address AS other_ip,
        lh.logged_at AS other_login_at
    FROM active_safe s
    JOIN ws_login_history lh
        ON lh.user_id = s.user_id
       AND lh.ip_address <> s.ip_address
    ORDER BY s.safe_ip_id, lh.logged_at DESC
)
SELECT
    los.ip_address AS "IP-адрес",
    u.login || ' — ' || COALESCE(u.extra_info, '') AS "Данные пользователя",
    los.login_count AS "Число входов с IP",
    los.last_login_at AS "Последний вход с IP",
    CASE
        WHEN los.last_login_at IS NULL THEN CURRENT_DATE - los.safe_ip_added_at::date
        ELSE CURRENT_DATE - los.last_login_at::date
    END AS "Дней без входа с IP",
    lo.other_login_at AS "Последний вход с другого IP",
    lo.other_ip AS "Другой IP",
    CASE WHEN u.is_blocked THEN 'да' ELSE 'нет' END AS "Заблокирован"
FROM login_on_safe los
JOIN ws_user u ON u.user_id = los.user_id
LEFT JOIN last_other lo ON lo.safe_ip_id = los.safe_ip_id
WHERE los.last_login_at IS NULL
   OR los.last_login_at < NOW() - INTERVAL '1 month'
ORDER BY
    CASE WHEN los.last_login_at IS NULL THEN CURRENT_DATE - los.safe_ip_added_at::date
         ELSE CURRENT_DATE - los.last_login_at::date
    END DESC NULLS FIRST,
    los.ip_address;
