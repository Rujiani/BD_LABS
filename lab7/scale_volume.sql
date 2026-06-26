-- Lab 7: bulk volume for EXPLAIN benchmarks (after ws_tools test-data).
-- Does not modify lab4 generator; uses deterministic unique IPs.
SET client_min_messages TO WARNING;

-- ~400k login events across existing users
INSERT INTO ws_login_history (user_id, ip_address, logged_at, extra_info)
SELECT
    u.user_id,
    ('10.' || ((g / 65000) % 200 + 50)::text || '.' ||
     ((g / 250) % 250 + 1)::text || '.' ||
     (g % 250 + 1)::text)::inet,
    NOW() - make_interval(days => (g % 400), hours => (g % 24), mins => (g % 60)),
    'lab7 bulk login'
FROM ws_user u
CROSS JOIN generate_series(1, 80) AS g
WHERE u.login LIKE 'td_%' OR u.login IN ('reader1', 'author1', 'risk_user');

-- ~500k additional views for Q5 benchmark (hash aggregate on document_id)
INSERT INTO ws_view_history (user_id, document_id, viewed_at, client_ip)
SELECT
    1 + (g % u.max_uid),
    1 + (g % d.max_did),
    NOW() - make_interval(days => (g % 365), hours => (g % 24)),
    ('10.0.' || (g % 200 + 1)::text || '.' || (g % 250 + 1)::text)::inet
FROM generate_series(1, 500000) AS g
CROSS JOIN (SELECT MAX(user_id) AS max_uid FROM ws_user) AS u
CROSS JOIN (SELECT MAX(document_id) AS max_did FROM ws_document) AS d;

-- Extra stale safe IPs (unique globally: encode user_id in address)
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT
    u.user_id,
    ('192.168.' || ((u.user_id / 256) % 256)::text || '.' || (u.user_id % 256)::text)::inet,
    NOW() - make_interval(days => 120),
    TRUE
FROM ws_user u
WHERE u.login LIKE 'td_%'
  AND u.user_id % 5 = 0
ON CONFLICT (ip_address) DO NOTHING;
