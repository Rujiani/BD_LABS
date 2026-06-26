CREATE OR REPLACE FUNCTION ws_trg_safe_ip_active_limit()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_excess INTEGER;
BEGIN
    SELECT GREATEST(COUNT(*) - 3, 0) INTO v_excess
    FROM ws_safe_ip WHERE user_id = NEW.user_id AND is_active;
    IF v_excess > 0 THEN
        UPDATE ws_safe_ip s SET is_active = FALSE
        FROM (
            SELECT safe_ip_id FROM ws_safe_ip
            WHERE user_id = NEW.user_id AND is_active
            ORDER BY added_at ASC, safe_ip_id ASC LIMIT v_excess
        ) o WHERE s.safe_ip_id = o.safe_ip_id;
    END IF;
    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_ws_safe_ip_active_limit ON ws_safe_ip;
CREATE TRIGGER trg_ws_safe_ip_active_limit
    AFTER INSERT OR UPDATE OF is_active ON ws_safe_ip
    FOR EACH ROW WHEN (NEW.is_active)
    EXECUTE FUNCTION ws_trg_safe_ip_active_limit();

SELECT trigger_name FROM information_schema.triggers
WHERE trigger_name = 'trg_ws_safe_ip_active_limit';
