-- БЕЗ триггера (до 08). ДЕМО ЦИКЛА — не путать с 07 (там перенос Законодательства).
-- Цепочка: Политика → Выборы → Регионы → Местные
-- UPDATE: parent Политики = Местные  →  цикл (Местные внутри своего потомка)

SELECT CASE WHEN COUNT(*) < 4
    THEN 'НЕТ 4 тем — cd lab6 && ./rebuild_db.sh'
    ELSE 'ok: ' || COUNT(*)::text || ' темы для цикла'
END AS check_cycle_branch
FROM ws_theme
WHERE name IN ('Политика', 'Выборы', 'Регионы', 'Местные');

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name,
       '' AS cycle_flag
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Политика', 'Выборы', 'Регионы', 'Местные')
ORDER BY CASE b.name
    WHEN 'Политика' THEN 1 WHEN 'Выборы' THEN 2
    WHEN 'Регионы' THEN 3 WHEN 'Местные' THEN 4 END;

UPDATE ws_theme
SET parent_id = (SELECT theme_id FROM ws_theme WHERE name = 'Местные')
WHERE name = 'Политика';

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name,
       CASE WHEN b.name = 'Политика' AND p.name = 'Местные'
            THEN 'ЦИКЛ' ELSE '' END AS cycle_flag
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Политика', 'Выборы', 'Регионы', 'Местные')
ORDER BY CASE b.name
    WHEN 'Политика' THEN 1 WHEN 'Выборы' THEN 2
    WHEN 'Регионы' THEN 3 WHEN 'Местные' THEN 4 END;
