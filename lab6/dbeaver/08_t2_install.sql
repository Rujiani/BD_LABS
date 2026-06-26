-- сброс после 08b (убираем цикл перед установкой триггера)

UPDATE ws_theme SET parent_id = NULL WHERE name = 'Политика';

CREATE OR REPLACE FUNCTION ws_trg_theme_no_cycle()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_cycle BOOLEAN;
BEGIN
    IF NEW.parent_id IS NULL THEN RETURN NEW; END IF;
    WITH RECURSIVE ancestors AS (
        SELECT theme_id, parent_id FROM ws_theme WHERE theme_id = NEW.parent_id
        UNION ALL
        SELECT t.theme_id, t.parent_id FROM ws_theme t
        JOIN ancestors a ON t.theme_id = a.parent_id
    )
    SELECT EXISTS (SELECT 1 FROM ancestors WHERE theme_id = NEW.theme_id) INTO v_cycle;
    IF v_cycle THEN
        RAISE EXCEPTION 'Циклическая зависимость тематик: theme_id=%', NEW.theme_id;
    END IF;
    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_ws_theme_no_cycle ON ws_theme;
CREATE TRIGGER trg_ws_theme_no_cycle
    BEFORE UPDATE OF parent_id ON ws_theme
    FOR EACH ROW EXECUTE FUNCTION ws_trg_theme_no_cycle();

SELECT trigger_name FROM information_schema.triggers
WHERE trigger_name = 'trg_ws_theme_no_cycle';
