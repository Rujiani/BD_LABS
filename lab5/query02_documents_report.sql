
WITH docs AS (
    SELECT
        d.document_id,
        d.title,
        u.login AS author_login,
        u.extra_info AS author_extra,
        COUNT(v.version_id) AS version_count,
        MIN(v.created_at) AS first_version_at,
        MAX(v.created_at) AS last_version_at
    FROM ws_document d
    JOIN ws_document_version v ON v.document_id = d.document_id
    JOIN ws_user u ON u.user_id = d.primary_author_id
    GROUP BY d.document_id, d.title, u.login, u.extra_info
),
view_stats AS (
    SELECT
        d.document_id,
        COUNT(vh.view_id) AS total_views,
        COUNT(DISTINCT vh.user_id) FILTER (
            WHERE vh.viewed_at >= d.last_version_at
        ) AS last_version_viewers
    FROM docs d
    LEFT JOIN ws_view_history vh ON vh.document_id = d.document_id
    GROUP BY d.document_id, d.last_version_at
),
fav_stats AS (
    SELECT f.document_id, COUNT(*) AS favorite_lists
    FROM ws_favorite f
    GROUP BY f.document_id
)
SELECT
    d.title AS "Название документа",
    d.first_version_at AS "Дата первой версии",
    d.last_version_at AS "Дата последней версии",
    d.version_count AS "Общее число версий",
    d.author_login || ' — ' || COALESCE(d.author_extra, '') AS "Автор",
    vs.last_version_viewers AS "Зрителей последней версии",
    vs.total_views AS "Просмотров всех версий",
    COALESCE(fs.favorite_lists, 0) AS "Списков избранного"
FROM docs d
LEFT JOIN view_stats vs ON vs.document_id = d.document_id
LEFT JOIN fav_stats fs ON fs.document_id = d.document_id
ORDER BY d.title;
