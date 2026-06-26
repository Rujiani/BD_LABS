
SET client_min_messages TO WARNING;

CREATE INDEX idx_safe_ip_active_user_ip
    ON ws_safe_ip (user_id, ip_address)
    WHERE is_active = TRUE;

ANALYZE ws_safe_ip;
