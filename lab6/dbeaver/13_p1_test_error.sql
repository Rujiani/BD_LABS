-- ошибка в Output: «Версия документа не найдена»

DO $$
BEGIN
    CALL ws_add_document_version(-1);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '%', SQLERRM;
END $$;

SELECT 'смотри Output — должна быть ошибка про version_id' AS result;
