# Shawarmap: вимоги та модель даних

## Призначення системи

Shawarmap -- платформа для пошуку, оцінювання та огляду закладів, які продають шаурму, буріто, донер-кебаб та подібні страви. Користувачі переглядають заклади, пропонують нові місця, залишають відгуки, коментарі, фото та скарги. Персонал закладу веде сторінку та рекламні кампанії; модератори й адміністратори переглядають матеріали та заявки.

## Потреби зацікавлених сторін

- **Гість** переглядає заклади й відгуки без реєстрації.
- **Користувач** створює профіль, додає заклади в обране, пропонує заклади, залишає відгуки й коментарі, завантажує фото та подає скарги.
- **Персонал закладу** редагує інформацію про заклад, меню, години роботи та фото; коментує відгуки від імені закладу та створює рекламу.
- **Модератор** розглядає заклади, рекламу й скарги та може приховувати матеріали, що порушують правила.
- **Адміністратор** перевіряє заявки на володіння закладом і керує ролями модераторів.

## Бізнес-правила

- Заклад розташований в одному місті, має назву, адресу, координати та контактні дані.
- Заклади класифікуються одним або кількома типами та можуть мати кілька особливостей.
- Години роботи зберігаються як записи за днями тижня; у поточній схемі кількість інтервалів для одного дня не обмежена унікальним обмеженням.
- Відгук має оцінку від 1 до 10. Середня оцінка обчислюється з відгуків і не зберігається.
- Коментар належить відгуку та може бути відповіддю на інший коментар. Офіційність коментаря й відповідність автора персоналу закладу є бізнес-правилами, які не перевіряються FK-обмеженнями.
- Фото належить або закладу, або відгуку. Рівно одне з цих двох посилань має бути заповнене.
- Скарга спрямована рівно на один відгук, коментар або заклад.
- Обліковий запис можна позначити видаленим через `status` і `deleted_at`. У DDL є перевірка, що ці поля узгоджені. Це не стирає автоматично персональні поля.
- Заявка на володіння стосується одного закладу й подається одним користувачем; її розглядає не більше одного адміністратора.
- Кожна рекламна кампанія належить одному закладу; її автор і модератор є необов'язковими зовнішніми ключами.
- Статистика збирається по днях. DDL перевіряє невід'ємність показів і кліків, але не встановлює унікальності кампанії/дати або правила `clicks <= impressions`.

## Сутності та атрибути

Позначення: **PK** — первинний ключ, **FK** — зовнішній ключ, **UK** — унікальне значення, `NULL` — поле може бути порожнім.

### `USERS`

Облікові записи користувачів платформи. Гість не зберігається.

| Атрибут | Тип | Ключ / обмеження |
| --- | --- | --- |
| `user_id` | `SERIAL` | PK |
| `email` | `VARCHAR(254)` | UK, NOT NULL |
| `pass_hash` | `TEXT` | NOT NULL |
| `display_name` | `VARCHAR(50)` | NOT NULL |
| `avatar_url` | `TEXT` | NULL |
| `role` | `user_role` | NOT NULL: `user`, `moderator`, `admin` |
| `status` | `user_status` | NOT NULL: `active`, `deleted` |
| `created_at` | `TIMESTAMPTZ` | NOT NULL |
| `deleted_at` | `TIMESTAMPTZ` | NULL |

Обмеження `chk_users_deleted_consistency` вимагає, щоб `status = 'deleted'` тоді й лише тоді, коли `deleted_at` не `NULL`.

### `CITY`, `VENUE_TYPE`, `FEATURE`

- `CITY`: `city_id SERIAL PK`, `name VARCHAR(255) NOT NULL`, `region VARCHAR(255) NOT NULL`.
- `VENUE_TYPE`: `venue_type_id SERIAL PK`, `name VARCHAR(255) UNIQUE NOT NULL`.
- `FEATURE`: `feature_id SERIAL PK`, `name VARCHAR(255) UNIQUE NOT NULL`.

### `VENUE`

| Атрибут | Тип | Ключ / обмеження |
| --- | --- | --- |
| `venue_id` | `SERIAL` | PK |
| `city_id` | `INT` | FK → `CITY.city_id`, NOT NULL |
| `created_by` | `INT` | FK → `USERS.user_id`, NULL |
| `status` | `venue_status` | NOT NULL: `pending`, `approved`, `rejected` |
| `name` | `VARCHAR(255)` | NOT NULL |
| `description`, `address`, `website` | `TEXT` | NOT NULL |
| `latitude`, `longitude` | `DOUBLE PRECISION` | NOT NULL; відповідно −90…90 та −180…180 |
| `phone_number` | `VARCHAR(20)` | NOT NULL |
| `created_at` | `TIMESTAMPTZ` | NOT NULL |

### Асоціативні сутності

| Таблиця | Колонки та ключі |
| --- | --- |
| `VENUE_VENUE_TYPE` | `venue_id INT PK/FK`, `venue_type_id INT PK/FK` |
| `VENUE_FEATURE` | `venue_id INT PK/FK`, `feature_id INT PK/FK` |
| `FAVORITE` | `user_id INT PK/FK`, `venue_id INT PK/FK`, `created_at TIMESTAMPTZ NOT NULL` |
| `VENUE_STAFF` | складений PK/FK (`venue_id`, `user_id`), `role venue_staff_role NOT NULL` (`owner`, `manager`), `added_by INT FK NULL`, `added_at TIMESTAMPTZ NOT NULL` |

### `WORKING_HOURS`, `MENU_ITEM`, `MODERATION_ACTION`

- `WORKING_HOURS`: `working_hours_id SERIAL PK`, `venue_id INT FK NOT NULL`, `weekday SMALLINT NOT NULL` (1–7), `opens_at TIME NOT NULL`, `closes_at TIME NOT NULL`.
- `MENU_ITEM`: `menu_item_id SERIAL PK`, `venue_id INT FK NOT NULL`, `name VARCHAR(255) NOT NULL`, `description TEXT NOT NULL`, `price DECIMAL(10,2) NOT NULL` (≥ 0), `is_available BOOLEAN NOT NULL`.
- `MODERATION_ACTION`: `moderation_action_id SERIAL PK`, `venue_id INT FK NOT NULL`, `moderator_id INT FK NOT NULL`, `action moderation_action_action NOT NULL` (`approve`, `reject`, `request_changes`), `note TEXT NOT NULL`, `created_at TIMESTAMPTZ NOT NULL`.

### `REVIEW`, `REVIEW_COMMENT`

- `REVIEW`: `review_id SERIAL PK`, `venue_id INT FK NOT NULL`, `user_id INT FK NULL`, `rating SMALLINT NOT NULL` (1–10), `text TEXT NOT NULL`, `visited_on DATE NOT NULL`, `status review_status NOT NULL` (`visible`, `hidden`), `created_at TIMESTAMPTZ NOT NULL`, `updated_at TIMESTAMPTZ NOT NULL`.
- `REVIEW_COMMENT`: `review_comment_id SERIAL PK`, `review_id INT FK NOT NULL`, `user_id INT FK NULL`, `parent_comment_id INT FK NULL` (самопосилання), `text TEXT NOT NULL`, `is_official BOOLEAN NOT NULL`, `created_at TIMESTAMPTZ NOT NULL`.

### `PHOTO`

`photo_id SERIAL PK`, `venue_id INT FK NULL`, `review_id INT FK NULL`, `uploaded_by INT FK NULL`, `url TEXT NOT NULL`, `created_at TIMESTAMPTZ NOT NULL`. Обмеження `chk_photo_target_xor` вимагає, щоб було заповнене рівно одне з `venue_id` та `review_id`.

### `REPORT`

`report_id SERIAL PK`, `reporter_id INT FK NULL`, `review_id INT FK NULL`, `comment_id INT FK NULL`, `venue_id INT FK NULL`, `reason TEXT NOT NULL`, `status report_status NOT NULL` (`open`, `resolved`, `dismissed`), `handled_by INT FK NULL`, `created_at TIMESTAMPTZ NOT NULL`. Обмеження `chk_report_target_exactly_one_of_three` вимагає рівно одну ціль серед `review_id`, `comment_id` та `venue_id`.

### `VENUE_CLAIM`

`venue_claim_id SERIAL PK`, `venue_id INT FK NOT NULL`, `claimant_id INT FK NOT NULL`, `contact_info TEXT NOT NULL`, `evidence TEXT NOT NULL`, `status venue_claim_status NOT NULL` (`pending`, `approved`, `rejected`), `reviewed_by INT FK NULL`, `reviewed_at TIMESTAMPTZ NULL`, `review_note TEXT NULL`, `created_at TIMESTAMPTZ NOT NULL`.

### `PROMOTION`, `PROMOTION_STAT`

- `PROMOTION`: `promotion_id SERIAL PK`, `venue_id INT FK NOT NULL`, `created_by INT FK NULL`, `type promotion_type NOT NULL` (`featured`, `offer`), `title TEXT NOT NULL`, `description TEXT NOT NULL`, `image_url TEXT NOT NULL`, `starts_at TIMESTAMPTZ NOT NULL`, `ends_at TIMESTAMPTZ NOT NULL`, `status promotion_status NOT NULL` (`draft`, `pending`, `active`, `ended`, `rejected`), `reviewed_by INT FK NULL`, `reviewed_at TIMESTAMPTZ NULL`, `review_note TEXT NULL`. `ends_at` має бути не раніше `starts_at`.
- `PROMOTION_STAT`: `promotion_stat_id SERIAL PK`, `promotion_id INT FK NOT NULL`, `stat_date DATE NOT NULL`, `impressions INT NOT NULL` (≥ 0), `clicks INT NOT NULL` (≥ 0).

## Зв'язки та кардинальність

- `CITY` 1:M `VENUE`; кожен `VENUE` належить одному місту.
- `USERS` 1:M `VENUE` як автор пропозиції; `created_by` необов'язковий.
- `VENUE` M:N `VENUE_TYPE` через `VENUE_VENUE_TYPE`.
- `VENUE` M:N `FEATURE` через `VENUE_FEATURE`.
- `USERS` M:N `VENUE` через `FAVORITE`.
- `VENUE` 1:M `WORKING_HOURS`, `MENU_ITEM`, `MODERATION_ACTION`, `REVIEW`, `VENUE_CLAIM` і `PROMOTION`.
- `USERS` можуть бути авторами або виконавцями `MODERATION_ACTION`, авторами `REVIEW`/`REVIEW_COMMENT`, завантажувачами `PHOTO`, авторами/обробниками `REPORT`, заявниками/перевіряльниками `VENUE_CLAIM`, персоналом `VENUE_STAFF` та авторами/перевіряльниками `PROMOTION`; необов'язкові посилання можуть бути `NULL`.
- `REVIEW` 1:M `REVIEW_COMMENT`; коментар належить одному відгуку. `REVIEW_COMMENT` може мати дочірні відповіді.
- `PHOTO` необов'язково посилається на один `VENUE` та необов'язково на один `REVIEW`, але XOR-обмеження вимагає рівно одну з цих цілей.
- `REPORT` необов'язково посилається на `REVIEW`, `REVIEW_COMMENT` або `VENUE`, але CHECK-обмеження вимагає рівно одну ціль.
- `PROMOTION` 1:M `PROMOTION_STAT`.

## Обмеження та відомі межі поточного DDL

- Діапазони координат, оцінки, дні тижня, ціни, дати кампаній та невід'ємність показів і кліків перевіряються SQL `CHECK`-обмеженнями.
- DDL не має `UNIQUE(venue_id, user_id)` для `REVIEW`; тому правило «не більше одного відгуку користувача на заклад» не гарантується базою.
- DDL не має `UNIQUE(venue_id, weekday)` для `WORKING_HOURS` або `UNIQUE(promotion_id, stat_date)` для `PROMOTION_STAT`; повтори для тих самих пар можливі.
- DDL не перевіряє, що `clicks <= impressions`, що автор офіційного коментаря є персоналом закладу, або що FK із роллю модератора/адміністратора посилається на користувача з відповідною роллю. Це правила рівня застосунку, якщо їх потрібно забезпечити.
- Зовнішні ключі задають `ON DELETE` поведінку: частина авторських посилань встановлюється в `NULL`, для `VENUE_STAFF` використовується каскадне видалення, а для інших зв'язків діють обмеження або каскади з DDL.

## Припущення та межі

- Підтримуються міста України; країна окремо не зберігається.
- Фотографії розміщені у зовнішньому сховищі, у БД зберігається URL.
- Оплата реклами та окремі події показів/кліків поза межами моделі.
- Статистика реклами агрегується по днях.
