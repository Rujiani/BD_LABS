WITH theme_doc AS (
    SELECT
        t.theme_id,
        t.name AS theme_name,
        t.description,
        d.document_id,
        d.title AS document_title,
        MAX(v.created_at) AS last_in_theme_at,
        d.primary_author_id
    FROM ws_theme t
    JOIN ws_version_theme vt ON vt.theme_id = t.theme_id
    JOIN ws_document_version v ON v.version_id = vt.version_id
    JOIN ws_document d ON d.document_id = v.document_id
    GROUP BY t.theme_id, t.name, t.description, d.document_id, d.title, d.primary_author_id
),
doc_views AS (
    SELECT document_id, COUNT(*) AS views
    FROM ws_view_history
    GROUP BY document_id
),
by_theme AS (
    SELECT
        td.theme_id,
        td.theme_name,
        td.description,
        COUNT(DISTINCT td.document_id) AS doc_count,
        COUNT(DISTINCT td.primary_author_id) AS author_count,
        SUM(COALESCE(dv.views, 0)) AS total_views
    FROM theme_doc td
    LEFT JOIN doc_views dv ON dv.document_id = td.document_id
    GROUP BY td.theme_id, td.theme_name, td.description
),
last_doc AS (
    SELECT DISTINCT ON (td.theme_id)
        td.theme_id,
        td.document_title,
        td.last_in_theme_at
    FROM theme_doc td
    ORDER BY td.theme_id, td.last_in_theme_at DESC, td.document_id DESC
)
SELECT
    bt.theme_name AS "Название тематики",
    COALESCE(bt.description, '') AS "Описание",
    bt.doc_count AS "Число документов",
    bt.author_count AS "Число авторов",
    bt.total_views AS "Общее число просмотров",
    ld.document_title AS "Последний документ",
    ld.last_in_theme_at AS "Дата последнего документа"
FROM by_theme bt
JOIN last_doc ld ON ld.theme_id = bt.theme_id
ORDER BY bt.theme_name;
