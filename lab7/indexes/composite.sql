SET client_min_messages TO WARNING;

CREATE INDEX idx_vh_viewed_user
    ON ws_view_history (viewed_at, user_id);

ANALYZE ws_view_history;
