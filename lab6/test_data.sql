-- lab6/test_data.sql — загружается через:  cd lab6 && ./rebuild_db.sh

SET client_min_messages TO WARNING;

-- =============================================================================
-- Пользователи lab6 (25 шт.: 0–3 safe IP, роли user/author)
-- =============================================================================

INSERT INTO ws_user (login, extra_info, role_id, last_ip, is_blocked)
SELECT v.login, v.extra_info, r.role_id, v.last_ip::inet, FALSE
FROM (VALUES
    ('lab6_user_01', 'lab6: 0 safe IP',           'user',   '172.30.0.1'),
    ('lab6_user_02', 'lab6: 1 safe IP',           'user',   '172.30.0.2'),
    ('lab6_user_03', 'lab6: 2 safe IP',           'user',   '172.30.0.3'),
    ('lab6_user_04', 'lab6: 3 safe IP',           'user',   '172.30.0.4'),
    ('lab6_user_05', 'lab6: 0 safe IP',           'user',   '172.30.0.5'),
    ('lab6_user_06', 'lab6: 1 safe IP',           'user',   '172.30.0.6'),
    ('lab6_user_07', 'lab6: 2 safe IP',           'user',   '172.30.0.7'),
    ('lab6_user_08', 'lab6: 3 safe IP',           'user',   '172.30.0.8'),
    ('lab6_user_09', 'lab6: 0 safe IP',           'user',   '172.30.0.9'),
    ('lab6_user_10', 'lab6: 1 safe IP',           'user',   '172.30.0.10'),
    ('lab6_user_11', 'lab6: 2 safe IP',           'user',   '172.30.0.11'),
    ('lab6_user_12', 'lab6: 3 safe IP',           'user',   '172.30.0.12'),
    ('lab6_user_13', 'lab6: 0 safe IP',           'user',   '172.30.0.13'),
    ('lab6_user_14', 'lab6: 1 safe IP',           'user',   '172.30.0.14'),
    ('lab6_user_15', 'lab6: 2 safe IP',           'user',   '172.30.0.15'),
    ('lab6_user_16', 'lab6: 3 safe IP',           'user',   '172.30.0.16'),
    ('lab6_user_17', 'lab6: 0 safe IP',           'user',   '172.30.0.17'),
    ('lab6_user_18', 'lab6: 1 safe IP',           'user',   '172.30.0.18'),
    ('lab6_user_19', 'lab6: 2 safe IP',           'user',   '172.30.0.19'),
    ('lab6_user_20', 'lab6: 3 safe IP',           'user',   '172.30.0.20'),
    ('lab6_user_21', 'lab6: автор, 0 safe IP',    'author', '172.30.0.21'),
    ('lab6_user_22', 'lab6: автор, 1 safe IP',    'author', '172.30.0.22'),
    ('lab6_bulk_user', 'lab6: массовая вставка IP', 'user', '172.30.1.0'),
    ('lab6_login_user',  'lab6: вход с safe IP',  'user',   '172.30.2.1'),
    ('lab6_login_user2', 'lab6: два safe IP',      'user',   '172.30.2.2'),
    ('lab6_tiebreak_user',   'lab6: тай-брейк safe_ip_id', 'user', '172.30.70.1'),
    ('lab6_inactive_ip_user', 'lab6: IP в списке, но неактивен', 'user', '172.30.80.1')
) AS v(login, extra_info, role_code, last_ip)
JOIN ws_role r ON r.role_code = v.role_code;

-- =============================================================================
-- Safe IP: 0–3 на пользователя lab6_user_01..20 (паттерн по номеру)
-- ip_address глобально уникален: 172.30.(100+NN).N (NN = right(login,2))
-- =============================================================================

INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id,
       format('172.30.%s.%s', 100 + right(u.login, 2)::int, n)::inet,
       TIMESTAMPTZ '2025-05-01 00:00:00+00' + (n * INTERVAL '1 hour'),
       TRUE
FROM ws_user u
CROSS JOIN generate_series(1, 3) AS n
WHERE u.login ~ '^lab6_user_[0-9]{2}$'
  AND (right(u.login, 2)::int - 1) % 4 >= n;

-- lab6_user_22 — один safe IP
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id, '172.30.11.22'::inet, TIMESTAMPTZ '2025-05-10 12:00:00+00', TRUE
FROM ws_user u WHERE u.login = 'lab6_user_22';

-- lab6_login_user — один safe IP (для процедуры ws_record_login)
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id, '172.30.2.10'::inet, TIMESTAMPTZ '2025-05-15 08:00:00+00', TRUE
FROM ws_user u WHERE u.login = 'lab6_login_user';

-- lab6_login_user2 — два safe IP
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id, ip, added_at, TRUE
FROM ws_user u
CROSS JOIN (VALUES
    ('172.30.2.20'::inet, TIMESTAMPTZ '2025-05-15 09:00:00+00'),
    ('172.30.2.21'::inet, TIMESTAMPTZ '2025-05-15 10:00:00+00')
) AS ips(ip, added_at)
WHERE u.login = 'lab6_login_user2';

-- Массовая вставка: пачка из 8 IP для lab6_bulk_user (тест триггера 1)
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id,
       ('172.30.50.' || gs.n)::inet,
       TIMESTAMPTZ '2025-06-01 00:00:00+00' + (gs.n * INTERVAL '10 minutes'),
       TRUE
FROM ws_user u
CROSS JOIN generate_series(1, 8) AS gs(n)
WHERE u.login = 'lab6_bulk_user';

-- Вторая пачка: 6 IP одним INSERT (для сценария bulk в test_scenarios)
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id, v.ip, v.added_at, TRUE
FROM ws_user u
CROSS JOIN (VALUES
    ('172.30.51.1'::inet, TIMESTAMPTZ '2025-06-02 01:00:00+00'),
    ('172.30.51.2'::inet, TIMESTAMPTZ '2025-06-02 02:00:00+00'),
    ('172.30.51.3'::inet, TIMESTAMPTZ '2025-06-02 03:00:00+00'),
    ('172.30.51.4'::inet, TIMESTAMPTZ '2025-06-02 04:00:00+00'),
    ('172.30.51.5'::inet, TIMESTAMPTZ '2025-06-02 05:00:00+00'),
    ('172.30.51.6'::inet, TIMESTAMPTZ '2025-06-02 06:00:00+00')
) AS v(ip, added_at)
WHERE u.login = 'lab6_bulk_user';

-- lab6_tiebreak_user — 4 IP с одинаковым added_at (тай-брейк по safe_ip_id)
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id, v.ip, TIMESTAMPTZ '2025-07-01 12:00:00+00', TRUE
FROM ws_user u
CROSS JOIN (VALUES
    ('172.30.70.1'::inet),
    ('172.30.70.2'::inet),
    ('172.30.70.3'::inet),
    ('172.30.70.4'::inet)
) AS v(ip)
WHERE u.login = 'lab6_tiebreak_user';

-- lab6_inactive_ip_user — IP в whitelist, но is_active = FALSE
INSERT INTO ws_safe_ip (user_id, ip_address, added_at, is_active)
SELECT u.user_id, '172.30.80.10'::inet, TIMESTAMPTZ '2025-07-02 08:00:00+00', FALSE
FROM ws_user u WHERE u.login = 'lab6_inactive_ip_user';

-- =============================================================================
-- Дерево тем: 8–12 узлов, 3–4 уровня (расширяет сид: Политика → Выборы → …)
-- =============================================================================

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Регионы', 'Региональные выборы', t.theme_id
FROM ws_theme t WHERE t.name = 'Выборы' LIMIT 1;

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Местные', 'Местное самоуправление', t.theme_id
FROM ws_theme t WHERE t.name = 'Регионы' LIMIT 1;

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Федеральная', 'Федеральный уровень', t.theme_id
FROM ws_theme t WHERE t.name = 'Политика' LIMIT 1;

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Законодательство', 'Нормативные акты', t.theme_id
FROM ws_theme t WHERE t.name = 'Федеральная' LIMIT 1;

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Финансы', 'Финансовый сектор', t.theme_id
FROM ws_theme t WHERE t.name = 'Экономика' LIMIT 1;

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Банки', 'Банковская система', t.theme_id
FROM ws_theme t WHERE t.name = 'Финансы' LIMIT 1;

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Торговля', 'Внешняя и внутренняя торговля', t.theme_id
FROM ws_theme t WHERE t.name = 'Экономика' LIMIT 1;

INSERT INTO ws_theme (name, description, parent_id)
SELECT 'Экспорт', 'Экспортные операции', t.theme_id
FROM ws_theme t WHERE t.name = 'Торговля' LIMIT 1;

-- Пара тем для теста короткого цикла A ↔ B
INSERT INTO ws_theme (name, description, parent_id) VALUES
    ('lab6_cycle_a', 'lab6: короткий цикл — узел A', NULL),
    ('lab6_cycle_b', 'lab6: короткий цикл — узел B', NULL);

-- =============================================================================
-- Информаторы для документов lab6
-- =============================================================================

INSERT INTO ws_informant (external_code, extra_info, categories) VALUES
    ('LAB6-INF-01', 'Источник lab6 для многоверсионных документов', ARRAY['lab6']),
    ('LAB6-INF-02', 'Второй источник lab6', ARRAY['lab6', 'регион'])
ON CONFLICT (external_code) DO NOTHING;

-- =============================================================================
-- 5 документов с 4–5 версиями (цепочка previous_version_id)
-- =============================================================================

INSERT INTO ws_document (title, doc_type, primary_author_id, extra_info)
SELECT d.title, d.doc_type, u.user_id, d.extra_info
FROM (VALUES
    ('lab6-doc-v5-01', 'table',   'Документ lab6: 5 версий'),
    ('lab6-doc-v5-02', 'text',    'Документ lab6: 4 версии'),
    ('lab6-doc-v5-03', 'image',   'Документ lab6: 5 версий'),
    ('lab6-doc-v5-04', 'archive', 'Документ lab6: 4 версии'),
    ('lab6-doc-v5-05', 'text',    'Документ lab6: 5 версий')
) AS d(title, doc_type, extra_info)
CROSS JOIN ws_user u
WHERE u.login = 'author1';

-- lab6-doc-v5-01: 5 версий
INSERT INTO ws_document_version (
    document_id, version_no, previous_version_id, created_at,
    edited_by_user_id, informant_id, body_preview
)
SELECT d.document_id, 1, NULL, TIMESTAMPTZ '2025-04-01 10:00:00+00',
       ua.user_id, i.informant_id, 'lab6 v1: начальный фрагмент'
FROM ws_document d
JOIN ws_user ua ON ua.login = 'author1'
JOIN ws_informant i ON i.external_code = 'LAB6-INF-01'
WHERE d.title = 'lab6-doc-v5-01';

INSERT INTO ws_document_version (
    document_id, version_no, previous_version_id, created_at,
    edited_by_user_id, informant_id, body_preview
)
SELECT d.document_id, 2, v1.version_id, TIMESTAMPTZ '2025-04-02 10:00:00+00',
       uc.user_id, i.informant_id, 'lab6 v2: дополнены строки'
FROM ws_document d
JOIN ws_document_version v1 ON v1.document_id = d.document_id AND v1.version_no = 1
JOIN ws_user uc ON uc.login = 'coauthor1'
JOIN ws_informant i ON i.external_code = 'LAB6-INF-01'
WHERE d.title = 'lab6-doc-v5-01';

INSERT INTO ws_document_version (
    document_id, version_no, previous_version_id, created_at,
    edited_by_user_id, informant_id, body_preview
)
SELECT d.document_id, 3, v2.version_id, TIMESTAMPTZ '2025-04-03 10:00:00+00',
       ua.user_id, i.informant_id, 'lab6 v3: проверка модератором'
FROM ws_document d
JOIN ws_document_version v2 ON v2.document_id = d.document_id AND v2.version_no = 2
JOIN ws_user ua ON ua.login = 'author1'
JOIN ws_informant i ON i.external_code = 'LAB6-INF-02'
WHERE d.title = 'lab6-doc-v5-01';

INSERT INTO ws_document_version (
    document_id, version_no, previous_version_id, created_at,
    edited_by_user_id, informant_id, body_preview
)
SELECT d.document_id, 4, v3.version_id, TIMESTAMPTZ '2025-04-04 10:00:00+00',
       ua.user_id, i.informant_id, 'lab6 v4: уточнение источников'
FROM ws_document d
JOIN ws_document_version v3 ON v3.document_id = d.document_id AND v3.version_no = 3
JOIN ws_user ua ON ua.login = 'author1'
JOIN ws_informant i ON i.external_code = 'LAB6-INF-02'
WHERE d.title = 'lab6-doc-v5-01';

INSERT INTO ws_document_version (
    document_id, version_no, previous_version_id, created_at,
    edited_by_user_id, informant_id, body_preview
)
SELECT d.document_id, 5, v4.version_id, TIMESTAMPTZ '2025-04-05 10:00:00+00',
       ua.user_id, i.informant_id, 'lab6 v5: финальная редакция'
FROM ws_document d
JOIN ws_document_version v4 ON v4.document_id = d.document_id AND v4.version_no = 4
JOIN ws_user ua ON ua.login = 'author1'
JOIN ws_informant i ON i.external_code = 'LAB6-INF-01'
WHERE d.title = 'lab6-doc-v5-01';

-- lab6-doc-v5-02: 4 версии
INSERT INTO ws_document_version (
    document_id, version_no, previous_version_id, created_at,
    edited_by_user_id, informant_id, body_preview
)
SELECT d.document_id, 1, NULL, TIMESTAMPTZ '2025-04-06 10:00:00+00',
       ua.user_id, i.informant_id, 'lab6 v1'
FROM ws_document d
JOIN ws_user ua ON ua.login = 'author1'
JOIN ws_informant i ON i.external_code = 'LAB6-INF-01'
WHERE d.title = 'lab6-doc-v5-02';

INSERT INTO ws_document_version (
    document_id, version_no, previous_version_id, created_at,
    edited_by_user_id, informant_id, body_preview
)
SELECT d.document_id, vn.version_no, prev.version_id, vn.created_at,
       ua.user_id, i.informant_id, vn.body_preview
FROM ws_document d
JOIN ws_user ua ON ua.login = 'author1'
JOIN ws_informant i ON i.external_code = 'LAB6-INF-01'
JOIN (VALUES
    (2, TIMESTAMPTZ '2025-04-07 10:00:00+00', 'lab6 v2'),
    (3, TIMESTAMPTZ '2025-04-08 10:00:00+00', 'lab6 v3'),
    (4, TIMESTAMPTZ '2025-04-09 10:00:00+00', 'lab6 v4')
) AS vn(version_no, created_at, body_preview) ON TRUE
JOIN ws_document_version prev
    ON prev.document_id = d.document_id AND prev.version_no = vn.version_no - 1
WHERE d.title = 'lab6-doc-v5-02';

-- lab6-doc-v5-03: 5 версий (компактная вставка)
DO $$
DECLARE
    doc_id INTEGER;
    author_id INTEGER;
    inf_id INTEGER;
    prev_vid INTEGER;
    new_vid INTEGER;
    vn INTEGER;
BEGIN
    SELECT d.document_id INTO doc_id FROM ws_document d WHERE d.title = 'lab6-doc-v5-03';
    SELECT u.user_id INTO author_id FROM ws_user u WHERE u.login = 'author1';
    SELECT i.informant_id INTO inf_id FROM ws_informant i WHERE i.external_code = 'LAB6-INF-02';

    INSERT INTO ws_document_version (
        document_id, version_no, previous_version_id, created_at,
        edited_by_user_id, informant_id, body_preview
    ) VALUES (
        doc_id, 1, NULL, TIMESTAMPTZ '2025-04-10 10:00:00+00',
        author_id, inf_id, 'lab6 v1'
    ) RETURNING version_id INTO prev_vid;

    FOR vn IN 2..5 LOOP
        INSERT INTO ws_document_version (
            document_id, version_no, previous_version_id, created_at,
            edited_by_user_id, informant_id, body_preview
        ) VALUES (
            doc_id, vn, prev_vid,
            TIMESTAMPTZ '2025-04-10 10:00:00+00' + ((vn - 1) * INTERVAL '1 day'),
            author_id, inf_id, 'lab6 v' || vn
        ) RETURNING version_id INTO new_vid;
        prev_vid := new_vid;
    END LOOP;
END $$;

-- lab6-doc-v5-04: 4 версии
DO $$
DECLARE
    doc_id INTEGER;
    author_id INTEGER;
    inf_id INTEGER;
    prev_vid INTEGER;
    new_vid INTEGER;
    vn INTEGER;
BEGIN
    SELECT d.document_id INTO doc_id FROM ws_document d WHERE d.title = 'lab6-doc-v5-04';
    SELECT u.user_id INTO author_id FROM ws_user u WHERE u.login = 'lab6_user_21';
    SELECT i.informant_id INTO inf_id FROM ws_informant i WHERE i.external_code = 'LAB6-INF-01';

    INSERT INTO ws_document_version (
        document_id, version_no, previous_version_id, created_at,
        edited_by_user_id, informant_id, body_preview
    ) VALUES (
        doc_id, 1, NULL, TIMESTAMPTZ '2025-04-15 10:00:00+00',
        author_id, inf_id, 'lab6 v1'
    ) RETURNING version_id INTO prev_vid;

    FOR vn IN 2..4 LOOP
        INSERT INTO ws_document_version (
            document_id, version_no, previous_version_id, created_at,
            edited_by_user_id, informant_id, body_preview
        ) VALUES (
            doc_id, vn, prev_vid,
            TIMESTAMPTZ '2025-04-15 10:00:00+00' + ((vn - 1) * INTERVAL '1 day'),
            author_id, inf_id, 'lab6 v' || vn
        ) RETURNING version_id INTO new_vid;
        prev_vid := new_vid;
    END LOOP;
END $$;

-- lab6-doc-v5-05: 5 версий
DO $$
DECLARE
    doc_id INTEGER;
    author_id INTEGER;
    inf_id INTEGER;
    prev_vid INTEGER;
    new_vid INTEGER;
    vn INTEGER;
BEGIN
    SELECT d.document_id INTO doc_id FROM ws_document d WHERE d.title = 'lab6-doc-v5-05';
    SELECT u.user_id INTO author_id FROM ws_user u WHERE u.login = 'lab6_user_22';
    SELECT i.informant_id INTO inf_id FROM ws_informant i WHERE i.external_code = 'LAB6-INF-02';

    INSERT INTO ws_document_version (
        document_id, version_no, previous_version_id, created_at,
        edited_by_user_id, informant_id, body_preview
    ) VALUES (
        doc_id, 1, NULL, TIMESTAMPTZ '2025-04-20 10:00:00+00',
        author_id, inf_id, 'lab6 v1'
    ) RETURNING version_id INTO prev_vid;

    FOR vn IN 2..5 LOOP
        INSERT INTO ws_document_version (
            document_id, version_no, previous_version_id, created_at,
            edited_by_user_id, informant_id, body_preview
        ) VALUES (
            doc_id, vn, prev_vid,
            TIMESTAMPTZ '2025-04-20 10:00:00+00' + ((vn - 1) * INTERVAL '1 day'),
            author_id, inf_id, 'lab6 v' || vn
        ) RETURNING version_id INTO new_vid;
        prev_vid := new_vid;
    END LOOP;
END $$;

-- Тематики версий lab6-документов
INSERT INTO ws_version_theme (version_id, theme_id)
SELECT v.version_id, t.theme_id
FROM ws_document_version v
JOIN ws_document d ON d.document_id = v.document_id
JOIN ws_theme t ON t.name IN ('Политика', 'Регионы', 'Местные')
WHERE d.title = 'lab6-doc-v5-01';

INSERT INTO ws_version_theme (version_id, theme_id)
SELECT v.version_id, t.theme_id
FROM ws_document_version v
JOIN ws_document d ON d.document_id = v.document_id
JOIN ws_theme t ON t.name IN ('Экономика', 'Финансы')
WHERE d.title = 'lab6-doc-v5-02';

INSERT INTO ws_version_theme (version_id, theme_id)
SELECT v.version_id, t.theme_id
FROM ws_document_version v
JOIN ws_document d ON d.document_id = v.document_id
JOIN ws_theme t ON t.name = 'Выборы'
WHERE d.title IN ('lab6-doc-v5-03', 'lab6-doc-v5-04', 'lab6-doc-v5-05');

-- Модерация последних версий
INSERT INTO ws_version_moderation (version_id, moderator_id, status, moderated_at, comment_text)
SELECT v.version_id, m.user_id, 'ready_for_publish'::ws_moderation_status,
       v.created_at + INTERVAL '2 hours', 'lab6: готово к публикации'
FROM ws_document_version v
JOIN ws_document d ON d.document_id = v.document_id
JOIN ws_user m ON m.login = 'mod1'
WHERE d.title LIKE 'lab6-doc-v5-%'
  AND v.version_no = (
      SELECT MAX(v2.version_no) FROM ws_document_version v2 WHERE v2.document_id = d.document_id
  );
