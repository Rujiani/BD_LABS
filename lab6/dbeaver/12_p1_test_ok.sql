-- после 11; CALL по v1 → новая v6 (previous на v5, не на v1)

SELECT d.title, d.extra_info,
       v.version_id, v.version_no, v.previous_version_id,
       u.login AS edited_by, v.body_preview
FROM ws_document d
JOIN ws_document_version v ON v.document_id = d.document_id
LEFT JOIN ws_user u ON u.user_id = v.edited_by_user_id
WHERE d.title LIKE 'lab6-doc-v5-01%'
ORDER BY v.version_no;

SELECT v.version_no, string_agg(t.name, ', ' ORDER BY t.name) AS themes
FROM ws_document d
JOIN ws_document_version v ON v.document_id = d.document_id
LEFT JOIN ws_version_theme vt ON vt.version_id = v.version_id
LEFT JOIN ws_theme t ON t.theme_id = vt.theme_id
WHERE d.title LIKE 'lab6-doc-v5-01%'
GROUP BY v.version_id, v.version_no
ORDER BY v.version_no;

DO $$
DECLARE v_vid INTEGER;
BEGIN
    SELECT v.version_id INTO v_vid
    FROM ws_document d
    JOIN ws_document_version v ON v.document_id = d.document_id
    WHERE d.title LIKE 'lab6-doc-v5-01%' AND v.version_no = 1;
    CALL ws_add_document_version(v_vid, p_title => 'lab6-doc-v5-01 (новое)');
END $$;

SELECT d.title, d.extra_info,
       v.version_id, v.version_no, v.previous_version_id,
       u.login AS edited_by, v.body_preview
FROM ws_document d
JOIN ws_document_version v ON v.document_id = d.document_id
LEFT JOIN ws_user u ON u.user_id = v.edited_by_user_id
WHERE d.title LIKE 'lab6-doc-v5-01%'
ORDER BY v.version_no;

SELECT v.version_no, string_agg(t.name, ', ' ORDER BY t.name) AS themes
FROM ws_document d
JOIN ws_document_version v ON v.document_id = d.document_id
LEFT JOIN ws_version_theme vt ON vt.version_id = v.version_id
LEFT JOIN ws_theme t ON t.theme_id = vt.theme_id
WHERE d.title LIKE 'lab6-doc-v5-01%'
GROUP BY v.version_id, v.version_no
ORDER BY v.version_no;
