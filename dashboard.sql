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
WITH last_paid_sessions AS (
    SELECT
        s.visitor_id,
        l.lead_id,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON
            s.visitor_id = l.visitor_id
            AND s.visit_date <= l.created_at
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)

SELECT
    COUNT(visitor_id) AS clicks_count,
    COUNT(lead_id) AS leads_count,
    COUNT(lead_id) FILTER (
        WHERE closing_reason = 'Успешно реализовано' OR status_id = 142
    ) AS purchases_count,
    ROUND(COUNT(lead_id)::numeric / NULLIF(COUNT(visitor_id), 0), 4)
        AS click_to_lead_conv,
    ROUND(
        COUNT(lead_id) FILTER (
            WHERE closing_reason = 'Успешно реализовано' OR status_id = 142
        )::numeric
        / NULLIF(COUNT(lead_id), 0),
        4
    ) AS lead_to_purchase_conv
FROM last_paid_sessions
WHERE rn = 1;

/* Расходы по каналам в динамике по дням */
SELECT
    DATE_TRUNC('day', campaign_date) AS spend_date,
    utm_source,
    SUM(daily_spent) AS total_cost
FROM (
    SELECT campaign_date, utm_source, daily_spent
    FROM vk_ads

    UNION ALL

    SELECT campaign_date, utm_source, daily_spent
    FROM ya_ads
) AS ads
GROUP BY
    DATE_TRUNC('day', campaign_date),
    utm_source
ORDER BY
    spend_date,
    utm_source;

/* Расходы по каналам в динамике по неделям */
SELECT
    DATE_TRUNC('week', campaign_date) AS spend_week,
    utm_source,
    SUM(daily_spent) AS total_cost
FROM (
    SELECT campaign_date, utm_source, daily_spent
    FROM vk_ads

    UNION ALL

    SELECT campaign_date, utm_source, daily_spent
    FROM ya_ads
) AS ads
GROUP BY
    DATE_TRUNC('week', campaign_date),
    utm_source
ORDER BY
    spend_week,
    utm_source;

/* Расходы по каналам в динамике по месяцам */
SELECT
    DATE_TRUNC('month', campaign_date) AS spend_month,
    utm_source,
    SUM(daily_spent) AS total_cost
FROM (
    SELECT campaign_date, utm_source, daily_spent
    FROM vk_ads

    UNION ALL

    SELECT campaign_date, utm_source, daily_spent
    FROM ya_ads
) AS ads
GROUP BY
    DATE_TRUNC('month', campaign_date),
    utm_source
ORDER BY
    spend_month,
    utm_source;
