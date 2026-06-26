
SET client_min_messages TO WARNING;

CREATE INDEX idx_vh_viewed_cover
    ON ws_view_history (viewed_at)
    INCLUDE (user_id, document_id);

CREATE INDEX idx_lh_user_ip_logged_cover
    ON ws_login_history (user_id, ip_address, logged_at DESC)
    INCLUDE (login_id);

ANALYZE ws_view_history;
ANALYZE ws_login_history;
