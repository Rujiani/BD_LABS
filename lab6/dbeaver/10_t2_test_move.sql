-- С триггером

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Экспорт', 'Банки', 'Торговля', 'Финансы')
ORDER BY b.name;

UPDATE ws_theme child
SET parent_id = bank.theme_id
FROM ws_theme child_row, ws_theme bank
WHERE child_row.name = 'Экспорт'
  AND bank.name = 'Банки'
  AND child.theme_id = child_row.theme_id;

SELECT b.theme_id, b.name, b.parent_id, p.name AS parent_name
FROM ws_theme b
LEFT JOIN ws_theme p ON p.theme_id = b.parent_id
WHERE b.name IN ('Экспорт', 'Банки', 'Торговля', 'Финансы')
ORDER BY b.name;
