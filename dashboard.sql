/* Количество уникальных пользователей */
SELECT COUNT(DISTINCT visitor_id) AS unique_visitors_count
FROM sessions;

/* Каналы, приводящие пользователей по дням (визиты) */
SELECT
    source,
    COUNT(*) AS visits_count,
    DATE_TRUNC('day', visit_date) as visit_date
FROM SESSIONS
GROUP BY
    source,
    DATE_TRUNC('day', visit_date)
ORDER BY visit_date;

/* Каналы, приводящие пользователей по неделям (визиты) */
SELECT
    source,
    COUNT(*) AS visits_count,
    DATE_TRUNC('week', visit_date) as visit_week
FROM SESSIONS
GROUP BY
    source,
    DATE_TRUNC('week', visit_date)
ORDER BY visit_week;

/* Каналы, приводящие пользователей по месяцам (визиты) */
SELECT
    source,
    COUNT(*) AS visits_count,
    DATE_TRUNC('month', visit_date) as visit_month
FROM SESSIONS
GROUP BY
    source,
    DATE_TRUNC('month', visit_date)
ORDER BY visit_month;

/* Каналы, приводящие пользователей по дням (уникальные пользователи) */
SELECT
    source,
    DATE_TRUNC('day', visit_date) AS visit_date,
    COUNT(DISTINCT visitor_id) AS users_count
FROM sessions
GROUP BY
    source,
    visit_date
ORDER BY
    visit_date;

/* Каналы, приводящие пользователей по неделям (уникальные пользователи) */
SELECT
    source,
    DATE_TRUNC('week', visit_date) AS visit_week,
    COUNT(DISTINCT visitor_id) AS users_count
FROM sessions
GROUP BY
    source,
    visit_week
ORDER BY
    visit_week;

/* Каналы, приводящие пользователей по месяцам (уникальные пользователи) */
SELECT
    source,
    DATE_TRUNC('month', visit_date) AS visit_month,
    COUNT(DISTINCT visitor_id) AS users_count
FROM sessions
GROUP BY
    source,
    visit_month
ORDER BY
    visit_month;

/* Приходящие лиды по дням */
SELECT
    DATE_TRUNC('day', created_at) AS lead_date,
    COUNT(*) AS leads_count
FROM leads
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY DATE_TRUNC('day', created_at);

/* Приходящие лиды по неделям */
SELECT
    DATE_TRUNC('week', created_at) AS lead_week,
    COUNT(*) AS leads_count
FROM leads
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY DATE_TRUNC('week', created_at);

/* Приходящие лиды по месяцам */
SELECT
    DATE_TRUNC('month', created_at) AS lead_month,
    COUNT(*) AS leads_count
FROM leads
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY DATE_TRUNC('month', created_at);

/* Конверсия из клика в лид и из лида в оплату */
