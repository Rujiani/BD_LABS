-- С триггером. active_count = 3

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

UPDATE ws_safe_ip s SET is_active = TRUE
FROM ws_user u
WHERE s.user_id = u.user_id
  AND u.login = 'safe3_user'
  AND s.ip_address = '10.0.0.13'::inet;

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
