DO $$
BEGIN
    CALL ws_record_login(999999, '10.0.0.1'::inet);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '%', SQLERRM;
END $$;

SELECT 'смотри Output — должна быть ошибка про user_id' AS result;
