-- БЕЗ триггера (до 08). Это ПЕРЕНОС, не цикл.
-- Законодательство → под Политику (легально, предков нет внизу).
-- Цикл — только в 08b (Политика → … → Местные → обратно к Политике).

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Законодательство', 'Политика', 'Федеральная')
ORDER BY b.name;

UPDATE ws_theme
SET parent_id = (SELECT theme_id FROM ws_theme WHERE name = 'Политика')
WHERE name = 'Законодательство';

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Законодательство', 'Политика', 'Федеральная')
ORDER BY b.name;
