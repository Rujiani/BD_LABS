CREATE OR REPLACE PROCEDURE ws_record_login(
    p_user_id   INTEGER,
    p_ip        INET
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_safe BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ws_user WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Пользователь с id % не найден', p_user_id;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM ws_safe_ip
        WHERE user_id = p_user_id
          AND ip_address = p_ip
          AND is_active
    )
    INTO v_is_safe;

    IF v_is_safe THEN
        INSERT INTO ws_login_history (user_id, ip_address)
        VALUES (p_user_id, p_ip);

        UPDATE ws_user
        SET last_ip = p_ip
        WHERE user_id = p_user_id;
    ELSE
        UPDATE ws_user
        SET is_blocked = TRUE
        WHERE user_id = p_user_id;

        INSERT INTO ws_block_event (user_id, event_type, comment_text)
        VALUES (
            p_user_id,
            'blocked',
            format('Вход с небезопасного IP: %s', p_ip)
        );

        INSERT INTO ws_login_history (user_id, ip_address)
        VALUES (p_user_id, p_ip);
    END IF;
END;
$$;
