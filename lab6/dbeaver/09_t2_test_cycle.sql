-- С триггером (после 08). 4 строки. cycle_flag пустой, ошибка в Output

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name,
       '' AS cycle_flag
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Политика', 'Выборы', 'Регионы', 'Местные')
ORDER BY CASE b.name
    WHEN 'Политика' THEN 1 WHEN 'Выборы' THEN 2
    WHEN 'Регионы' THEN 3 WHEN 'Местные' THEN 4 END;

DO $$
BEGIN
    UPDATE ws_theme
    SET parent_id = (SELECT theme_id FROM ws_theme WHERE name = 'Местные')
    WHERE name = 'Политика';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '%', SQLERRM;
END $$;

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name,
       CASE WHEN b.name = 'Политика' AND p.name = 'Местные'
            THEN 'ЦИКЛ' ELSE '' END AS cycle_flag
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Политика', 'Выборы', 'Регионы', 'Местные')
ORDER BY CASE b.name
    WHEN 'Политика' THEN 1 WHEN 'Выборы' THEN 2
    WHEN 'Регионы' THEN 3 WHEN 'Местные' THEN 4 END;
