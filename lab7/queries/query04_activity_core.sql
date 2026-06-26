-- (без crosstab).
WITH bounds AS (
    SELECT
        date_trunc('week', CURRENT_DATE) - INTERVAL '1 week' AS report_start,
        date_trunc('week', CURRENT_DATE) AS report_end
),
active AS (
    SELECT DISTINCT
        v.user_id,
        (v.viewed_at::date - b.report_start::date) AS day_offset,
        EXTRACT(HOUR FROM v.viewed_at)::int / 3 AS slot_idx
    FROM ws_view_history v
    CROSS JOIN bounds b
    WHERE v.viewed_at >= b.report_start
      AND v.viewed_at < b.report_end
),
users AS (
    SELECT DISTINCT a.user_id, u.login
    FROM active a
    JOIN ws_user u ON u.user_id = a.user_id
),
slots AS (
    SELECT
        d.day_offset * 8 + h.slot_idx + 1 AS sort_ord,
        d.day_offset AS day_offset,
        h.slot_idx AS slot_idx
    FROM generate_series(0, 6) AS d(day_offset)
    CROSS JOIN generate_series(0, 7) AS h(slot_idx)
)
SELECT
    u.login AS "Имя пользователя",
    s.sort_ord AS "Слот",
    CASE WHEN a.user_id IS NOT NULL THEN 'да' ELSE 'нет' END AS "Активен"
FROM users u
CROSS JOIN slots s
LEFT JOIN active a
    ON a.user_id    = u.user_id
   AND a.day_offset = s.day_offset
   AND a.slot_idx   = s.slot_idx
ORDER BY u.login, s.sort_ord;
