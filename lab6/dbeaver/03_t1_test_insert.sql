-- БЕЗ триггера (до 04). active_count = 4

SELECT s.safe_ip_id,
       s.user_id,
       u.login,
       u.last_ip,
       u.is_blocked,
       s.ip_address,
       s.is_active,
       s.added_at
FROM ws_safe_ip s
JOIN ws_user u ON u.user_id = s.user_id
WHERE u.login = 'safe3_user'
ORDER BY s.is_active DESC, s.added_at, s.safe_ip_id;

INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT user_id, '10.0.0.99'::inet, now(), TRUE
FROM ws_user WHERE login = 'safe3_user';

SELECT s.safe_ip_id,
       s.user_id,
       u.login,
       u.last_ip,
       u.is_blocked,
       s.ip_address,
       s.is_active,
       s.added_at
FROM ws_safe_ip s
JOIN ws_user u ON u.user_id = s.user_id
WHERE u.login = 'safe3_user'
ORDER BY s.is_active DESC, s.added_at, s.safe_ip_id;

SELECT COUNT(*) FILTER (WHERE s.is_active)     AS active_count,
       COUNT(*) FILTER (WHERE NOT s.is_active) AS inactive_count,
       COUNT(*)                                AS total_count
FROM ws_safe_ip s
JOIN ws_user u ON u.user_id = s.user_id
WHERE u.login = 'safe3_user';
