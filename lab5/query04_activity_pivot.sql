CREATE EXTENSION IF NOT EXISTS tablefunc;

DROP TABLE IF EXISTS _q4_flags;
CREATE TEMP TABLE _q4_flags AS
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
    u.login,
    s.sort_ord,
    CASE WHEN a.user_id IS NOT NULL THEN 'да' ELSE 'нет' END AS mark
FROM users u
CROSS JOIN slots s
LEFT JOIN active a
    ON a.user_id    = u.user_id
   AND a.day_offset = s.day_offset
   AND a.slot_idx   = s.slot_idx
ORDER BY u.login, s.sort_ord;

SELECT *
FROM crosstab(
    'SELECT login, sort_ord, mark FROM _q4_flags ORDER BY login, sort_ord',
    'SELECT generate_series(1, 56)'
) AS ct (
    "Имя пользователя" text,
    "пн_00-03ч" text, "пн_03-06ч" text, "пн_06-09ч" text, "пн_09-12ч" text,
    "пн_12-15ч" text, "пн_15-18ч" text, "пн_18-21ч" text, "пн_21-24ч" text,
    "вт_00-03ч" text, "вт_03-06ч" text, "вт_06-09ч" text, "вт_09-12ч" text,
    "вт_12-15ч" text, "вт_15-18ч" text, "вт_18-21ч" text, "вт_21-24ч" text,
    "ср_00-03ч" text, "ср_03-06ч" text, "ср_06-09ч" text, "ср_09-12ч" text,
    "ср_12-15ч" text, "ср_15-18ч" text, "ср_18-21ч" text, "ср_21-24ч" text,
    "чт_00-03ч" text, "чт_03-06ч" text, "чт_06-09ч" text, "чт_09-12ч" text,
    "чт_12-15ч" text, "чт_15-18ч" text, "чт_18-21ч" text, "чт_21-24ч" text,
    "пт_00-03ч" text, "пт_03-06ч" text, "пт_06-09ч" text, "пт_09-12ч" text,
    "пт_12-15ч" text, "пт_15-18ч" text, "пт_18-21ч" text, "пт_21-24ч" text,
    "сб_00-03ч" text, "сб_03-06ч" text, "сб_06-09ч" text, "сб_09-12ч" text,
    "сб_12-15ч" text, "сб_15-18ч" text, "сб_18-21ч" text, "сб_21-24ч" text,
    "вс_00-03ч" text, "вс_03-06ч" text, "вс_06-09ч" text, "вс_09-12ч" text,
    "вс_12-15ч" text, "вс_15-18ч" text, "вс_18-21ч" text, "вс_21-24ч" text
)
ORDER BY "Имя пользователя";
