WITH shared_ip AS (
    SELECT ip_address
    FROM ws_login_history
    GROUP BY ip_address
    HAVING COUNT(DISTINCT user_id) >= 2
),
per_user AS (
    SELECT
        lh.ip_address,
        lh.user_id,
        u.login,
        u.extra_info,
        MIN(lh.logged_at) AS first_login,
        MAX(lh.logged_at) AS last_login,
        COUNT(*) AS login_count
    FROM ws_login_history lh
    JOIN shared_ip si ON si.ip_address = lh.ip_address
    JOIN ws_user u ON u.user_id = lh.user_id
    GROUP BY lh.ip_address, lh.user_id, u.login, u.extra_info
),
pairs AS (
    SELECT
        a.ip_address,
        a.user_id AS user1_id,
        a.login AS user1_login,
        a.extra_info AS user1_extra,
        a.first_login AS user1_first,
        a.last_login AS user1_last,
        a.login_count AS user1_count,
        b.user_id AS user2_id,
        b.login AS user2_login,
        b.extra_info AS user2_extra,
        b.first_login AS user2_first,
        b.last_login AS user2_last,
        b.login_count AS user2_count
    FROM per_user a
    JOIN per_user b
        ON b.ip_address = a.ip_address
       AND b.user_id > a.user_id
),
pair_logins AS (
    SELECT
        p.ip_address,
        p.user1_id,
        p.user2_id,
        lh.logged_at,
        lh.user_id,
        lh.login_id
    FROM pairs p
    JOIN ws_login_history lh
        ON lh.ip_address = p.ip_address
       AND lh.user_id IN (p.user1_id, p.user2_id)
),
with_next AS (
    SELECT
        pl.ip_address,
        pl.user1_id,
        pl.user2_id,
        pl.logged_at,
        pl.user_id,
        LEAD(pl.logged_at) OVER (
            PARTITION BY pl.ip_address, pl.user1_id, pl.user2_id
            ORDER BY pl.logged_at, pl.login_id
        ) AS next_logged_at,
        LEAD(pl.user_id) OVER (
            PARTITION BY pl.ip_address, pl.user1_id, pl.user2_id
            ORDER BY pl.logged_at, pl.login_id
        ) AS next_user_id
    FROM pair_logins pl
),
closest AS (
    SELECT DISTINCT ON (wn.ip_address, wn.user1_id, wn.user2_id)
        wn.ip_address,
        wn.user1_id,
        wn.user2_id,
        CASE
            WHEN wn.user_id = wn.user1_id THEN wn.logged_at
            ELSE wn.next_logged_at
        END AS login1_at,
        CASE
            WHEN wn.user_id = wn.user1_id THEN wn.next_logged_at
            ELSE wn.logged_at
        END AS login2_at,
        ROUND(
            (ABS(EXTRACT(EPOCH FROM (wn.logged_at - wn.next_logged_at))) / 60)::numeric,
            2
        ) AS diff_minutes
    FROM with_next wn
    WHERE wn.next_user_id IS NOT NULL
      AND wn.user_id <> wn.next_user_id
    ORDER BY
        wn.ip_address,
        wn.user1_id,
        wn.user2_id,
        ABS(EXTRACT(EPOCH FROM (wn.logged_at - wn.next_logged_at))),
        wn.logged_at,
        wn.next_logged_at
)
SELECT
    p.ip_address AS "IP-адрес",
    p.user1_login || ' — ' || COALESCE(p.user1_extra, '') AS "Данные первого пользователя",
    p.user1_first AS "Первый вход (пользователь 1)",
    p.user1_last AS "Последний вход (пользователь 1)",
    p.user1_count AS "Число входов (пользователь 1)",
    p.user2_login || ' — ' || COALESCE(p.user2_extra, '') AS "Данные второго пользователя",
    p.user2_first AS "Первый вход (пользователь 2)",
    p.user2_last AS "Последний вход (пользователь 2)",
    p.user2_count AS "Число входов (пользователь 2)",
    c.login1_at AS "Ближайший вход пользователя 1",
    c.login2_at AS "Ближайший вход пользователя 2",
    c.diff_minutes AS "Разница, минуты"
FROM pairs p
JOIN closest c
    ON c.ip_address = p.ip_address
   AND c.user1_id = p.user1_id
   AND c.user2_id = p.user2_id
ORDER BY p.ip_address, p.user1_login, p.user2_login;