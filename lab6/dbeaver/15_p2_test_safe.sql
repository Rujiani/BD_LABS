-- после 14

SELECT u.login, u.user_id, u.is_blocked, u.last_ip, u.extra_info
FROM ws_user u WHERE u.login = 'lab6_login_user';

SELECT s.safe_ip_id, s.ip_address, s.is_active, s.added_at
FROM ws_safe_ip s
JOIN ws_user u ON u.user_id = s.user_id
WHERE u.login = 'lab6_login_user'
ORDER BY s.added_at;

SELECT h.logged_at, h.ip_address
FROM ws_login_history h
JOIN ws_user u ON u.user_id = h.user_id
WHERE u.login = 'lab6_login_user'
ORDER BY h.logged_at DESC
LIMIT 5;

DO $$
DECLARE u INTEGER;
BEGIN
    SELECT user_id INTO u FROM ws_user WHERE login = 'lab6_login_user';
    CALL ws_record_login(u, '172.30.2.10'::inet);
END $$;

SELECT u.login, u.is_blocked, u.last_ip
FROM ws_user u WHERE u.login = 'lab6_login_user';

SELECT h.logged_at, h.ip_address
FROM ws_login_history h
JOIN ws_user u ON u.user_id = h.user_id
WHERE u.login = 'lab6_login_user'
ORDER BY h.logged_at DESC
LIMIT 5;

SELECT be.occurred_at, be.event_type, be.comment_text
FROM ws_block_event be
JOIN ws_user u ON u.user_id = be.user_id
WHERE u.login = 'lab6_login_user'
ORDER BY be.occurred_at DESC
LIMIT 3;
