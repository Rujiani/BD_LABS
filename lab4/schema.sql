SET client_min_messages TO WARNING;

CREATE TYPE ws_moderation_status AS ENUM (
    'rejected',
    'sent_for_revision',
    'ready_for_publish'
);

CREATE TYPE ws_block_event_type AS ENUM (
    'blocked',
    'unblocked'
);

CREATE TABLE ws_role (
    role_id       SERIAL PRIMARY KEY,
    role_code     VARCHAR(32) NOT NULL UNIQUE,
    CONSTRAINT ck_ws_role_code_allowed CHECK (
        role_code IN ('user', 'author', 'moderator', 'admin')
    )
);

CREATE TABLE ws_user (
    user_id            SERIAL PRIMARY KEY,
    login              VARCHAR(64) NOT NULL UNIQUE,
    extra_info         TEXT,
    role_id            INTEGER NOT NULL REFERENCES ws_role (role_id),
    last_ip            INET,
    is_blocked         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_ws_user_login_nonempty CHECK (char_length(btrim(login)) > 0)
);

CREATE TABLE ws_document (
    document_id   SERIAL PRIMARY KEY,
    title         VARCHAR(512) NOT NULL,
    doc_type      VARCHAR(64) NOT NULL,
    primary_author_id INTEGER NOT NULL REFERENCES ws_user (user_id),
    extra_info    TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_ws_document_title_nonempty CHECK (char_length(btrim(title)) > 0),
    CONSTRAINT ck_ws_document_doc_type_allowed CHECK (
        doc_type IN ('text', 'table', 'image', 'archive')
    )
);

CREATE TABLE ws_document_coauthor (
    document_id   INTEGER NOT NULL REFERENCES ws_document (document_id) ON DELETE CASCADE,
    coauthor_id   INTEGER NOT NULL REFERENCES ws_user (user_id) ON DELETE CASCADE,
    assigned_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (document_id, coauthor_id)
);


CREATE TABLE ws_informant (
    informant_id   SERIAL PRIMARY KEY,
    external_code  VARCHAR(128) NOT NULL UNIQUE,
    extra_info     TEXT,
    categories     TEXT[] NOT NULL DEFAULT '{}'::text[],
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE ws_document_version (
    version_id          SERIAL PRIMARY KEY,
    document_id         INTEGER NOT NULL REFERENCES ws_document (document_id) ON DELETE CASCADE,
    version_no          INTEGER NOT NULL,
    previous_version_id INTEGER REFERENCES ws_document_version (version_id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    edited_by_user_id   INTEGER NOT NULL REFERENCES ws_user (user_id),
    informant_id        INTEGER REFERENCES ws_informant (informant_id),
    body_preview        TEXT,
    CONSTRAINT uq_ws_document_version_no UNIQUE (document_id, version_no),
    CONSTRAINT ck_ws_document_version_no_positive CHECK (version_no >= 1),
    CONSTRAINT ck_ws_document_version_previous_chain CHECK (
        (version_no = 1 AND previous_version_id IS NULL)
        OR (version_no > 1 AND previous_version_id IS NOT NULL)
    )
);

CREATE TABLE ws_theme (
    theme_id     SERIAL PRIMARY KEY,
    name         VARCHAR(256) NOT NULL,
    description  TEXT,
    parent_id    INTEGER REFERENCES ws_theme (theme_id) ON DELETE SET NULL,
    CONSTRAINT ck_ws_theme_no_self_parent CHECK (parent_id IS DISTINCT FROM theme_id),
    CONSTRAINT ck_ws_theme_name_nonempty CHECK (char_length(btrim(name)) > 0)
);

CREATE TABLE ws_version_theme (
    version_id   INTEGER NOT NULL REFERENCES ws_document_version (version_id) ON DELETE CASCADE,
    theme_id     INTEGER NOT NULL REFERENCES ws_theme (theme_id) ON DELETE RESTRICT,
    PRIMARY KEY (version_id, theme_id)
);

CREATE TABLE ws_version_moderation (
    version_id      INTEGER PRIMARY KEY REFERENCES ws_document_version (version_id) ON DELETE CASCADE,
    moderator_id    INTEGER NOT NULL REFERENCES ws_user (user_id),
    status          ws_moderation_status NOT NULL,
    moderated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    comment_text    TEXT
);

CREATE TABLE ws_favorite (
    user_id       INTEGER NOT NULL REFERENCES ws_user (user_id) ON DELETE CASCADE,
    document_id   INTEGER NOT NULL REFERENCES ws_document (document_id) ON DELETE CASCADE,
    added_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, document_id)
);

CREATE TABLE ws_view_history (
    view_id       BIGSERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES ws_user (user_id) ON DELETE CASCADE,
    document_id   INTEGER NOT NULL REFERENCES ws_document (document_id) ON DELETE CASCADE,
    viewed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    client_ip     INET NOT NULL
);

CREATE INDEX idx_ws_view_history_user_time ON ws_view_history (user_id, viewed_at DESC);
CREATE INDEX idx_ws_view_history_document ON ws_view_history (document_id);

CREATE TABLE ws_safe_ip (
    safe_ip_id    SERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES ws_user (user_id) ON DELETE CASCADE,
    ip_address    INET NOT NULL UNIQUE,
    added_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_ws_safe_ip_user_ip UNIQUE (user_id, ip_address)
);

CREATE TABLE ws_login_history (
    login_id      BIGSERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES ws_user (user_id) ON DELETE CASCADE,
    ip_address    INET NOT NULL,
    logged_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    extra_info    TEXT
);

CREATE INDEX idx_ws_login_history_user ON ws_login_history (user_id, logged_at DESC);

CREATE TABLE ws_block_event (
    event_id      BIGSERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES ws_user (user_id) ON DELETE CASCADE,
    event_type    ws_block_event_type NOT NULL,
    occurred_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    comment_text  TEXT,
    actor_id      INTEGER REFERENCES ws_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_ws_block_event_actor_unblock CHECK (
        event_type <> 'unblocked' OR actor_id IS NOT NULL
    )
);

CREATE INDEX idx_ws_block_event_user ON ws_block_event (user_id, occurred_at DESC);

CREATE TABLE ws_comment (
    comment_id    BIGSERIAL PRIMARY KEY,
    document_id   INTEGER NOT NULL REFERENCES ws_document (document_id) ON DELETE CASCADE,
    author_id     INTEGER NOT NULL REFERENCES ws_user (user_id) ON DELETE RESTRICT,
    parent_id     BIGINT REFERENCES ws_comment (comment_id) ON DELETE CASCADE,
    mention_user_id INTEGER REFERENCES ws_user (user_id) ON DELETE SET NULL,
    body          TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    client_ip     INET NOT NULL,
    CONSTRAINT ck_ws_comment_body_nonempty CHECK (char_length(btrim(body)) > 0),
    CONSTRAINT ck_ws_comment_no_self_parent CHECK (parent_id IS DISTINCT FROM comment_id)
);

CREATE INDEX idx_ws_comment_document ON ws_comment (document_id, created_at);
