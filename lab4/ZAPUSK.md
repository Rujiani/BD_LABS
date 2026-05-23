
## 1. Требования

- PostgreSQL и клиентские утилиты: `psql`, `createdb`, `dropdb`.
- Учётка БД/ОС, которая может создавать базы (или суперпользователь БД).
- Python **3.10+**.
- Генераторы `seed.sql` и `test_data.sql` используют только стандартную библиотеку Python (`Scripts/requirements.txt` может быть пустым).


## 2. Полное пересоздание базы (schema + seed)

Скрипт `Scripts/recreate_db.sh` делает следующее:

- завершает активные сессии к целевой базе;
- выполняет `dropdb` / `createdb`;
- **генерирует актуальный `db/seed.sql`** командой `python3 Scripts/ws_tools.py seed-sql`;
- применяет `db/schema.sql`;
- применяет `db/seed.sql`;

Запуск:

```bash
chmod +x Scripts/recreate_db.sh   # один раз
export PGDATABASE=wikisneaks
./Scripts/recreate_db.sh
```

## 3. Генерация (или проверка) `db/seed.sql` вручную

Сгенерировать заново:

```bash
python3 Scripts/ws_tools.py seed-sql --out db/seed.sql
```

Проверить, что `db/seed.sql` совпадает с генератором:

```bash
python3 Scripts/ws_tools.py seed-sql --check --out db/seed.sql
```

## 4. Генерация объёмных тестовых данных (`db/test_data.sql`)

Сначала соберите файл SQL (детерминированно от `--seed`). Предусмотрено, что в БД уже есть данные из `schema.sql` и `seed.sql` (роли, модератор из сида, базовые темы и т.д.).

```bash
python3 Scripts/ws_tools.py test-data --out db/test_data.sql --users 80 --documents 40 --versions-max 5 --seed 7
```

Затем подставьте дамп в нужную базу:

```bash
export PGDATABASE=wikisneaks
psql -v ON_ERROR_STOP=1 -f db/test_data.sql
```

Параметры:

- `--out`: куда записать SQL (по умолчанию `db/test_data.sql`).
- `--users`: сколько добавить **новых** пользователей.
- `--documents`: сколько добавить **новых** документов (с версиями, модерацией, связями).
- `--versions-max`: верхняя граница числа версий на документ.
- `--seed`: зерно ГПСЧ (для воспроизводимого прогона).
