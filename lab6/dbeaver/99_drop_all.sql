DROP TRIGGER IF EXISTS trg_ws_safe_ip_active_limit ON ws_safe_ip;
DROP TRIGGER IF EXISTS trg_ws_theme_no_cycle ON ws_theme;
DROP FUNCTION IF EXISTS ws_trg_safe_ip_active_limit();
DROP FUNCTION IF EXISTS ws_trg_theme_no_cycle();
DROP PROCEDURE IF EXISTS ws_add_document_version(INTEGER, INTEGER, INTEGER, TEXT, TEXT);
DROP PROCEDURE IF EXISTS ws_record_login(INTEGER, INET);

SELECT 'триггеры и процедуры lab6 сняты' AS status;
