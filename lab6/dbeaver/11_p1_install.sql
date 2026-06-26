DROP PROCEDURE IF EXISTS ws_add_document_version(INTEGER, INTEGER, INTEGER, TEXT, TEXT);

CREATE OR REPLACE PROCEDURE ws_add_document_version(
    p_previous_version_id INTEGER,
    p_author_id INTEGER DEFAULT NULL,
    p_theme_id INTEGER DEFAULT NULL,
    p_title TEXT DEFAULT NULL,
    p_extra_info TEXT DEFAULT NULL
) LANGUAGE plpgsql AS $$
DECLARE
    v_document_id INTEGER;
    v_latest ws_document_version%ROWTYPE;
    v_new_version_id INTEGER;
    v_new_no INTEGER;
BEGIN
    SELECT document_id INTO v_document_id
    FROM ws_document_version WHERE version_id = p_previous_version_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Версия документа не найдена: version_id=%', p_previous_version_id;
    END IF;
    SELECT * INTO v_latest FROM ws_document_version
    WHERE document_id = v_document_id ORDER BY version_no DESC LIMIT 1;
    v_new_no := v_latest.version_no + 1;
    INSERT INTO ws_document_version (
        document_id, version_no, previous_version_id,
        edited_by_user_id, informant_id, body_preview
    ) VALUES (
        v_document_id, v_new_no, v_latest.version_id,
        COALESCE(p_author_id, v_latest.edited_by_user_id),
        v_latest.informant_id, v_latest.body_preview
    ) RETURNING version_id INTO v_new_version_id;
    UPDATE ws_document
    SET title = COALESCE(p_title, title), extra_info = COALESCE(p_extra_info, extra_info)
    WHERE document_id = v_document_id;
    IF p_theme_id IS NOT NULL THEN
        INSERT INTO ws_version_theme VALUES (v_new_version_id, p_theme_id);
    ELSE
        INSERT INTO ws_version_theme (version_id, theme_id)
        SELECT v_new_version_id, vt.theme_id FROM ws_version_theme vt
        WHERE vt.version_id = v_latest.version_id;
    END IF;
END; $$;

SELECT proname FROM pg_proc WHERE proname = 'ws_add_document_version';
