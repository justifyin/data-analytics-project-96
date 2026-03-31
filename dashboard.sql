/* Количество уникальных пользователей */
SELECT COUNT(DISTINCT visitor_id) AS unique_visitors_count
FROM sessions;

/* Каналы, приводящие пользователей по дням */
SELECT
    SOURCE,
    COUNT(*),
    DATE_TRUNC('day', visit_date) as visit_date
FROM SESSIONS
GROUP BY 1, 3
ORDER BY visit_date;

/* Каналы, приводящие пользователей по неделям */
SELECT
    SOURCE,
    COUNT(*),
    DATE_TRUNC('day', visit_date) as visit_week
FROM SESSIONS
GROUP BY 1, 3
ORDER BY visit_week;

/* Приходящие лиды по дням */
SELECT
    DATE_TRUNC('day', created_at),
    COUNT(*)
FROM leads
GROUP BY 1
ORDER BY 1;

/* Конверсия из клика в лид и из лида в оплату */
