-- после 14

SELECT u.login, u.user_id, u.is_blocked, u.last_ip
FROM ws_user u WHERE u.login = 'lab6_login_user';

SELECT s.ip_address, s.is_active FROM ws_safe_ip s
JOIN ws_user u ON u.user_id = s.user_id
WHERE u.login = 'lab6_login_user';

DO $$
DECLARE u INTEGER;
BEGIN
    SELECT user_id INTO u FROM ws_user WHERE login = 'lab6_login_user';
    CALL ws_record_login(u, '203.0.113.99'::inet);
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
