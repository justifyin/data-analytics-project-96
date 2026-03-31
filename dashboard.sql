/* Количество уникальных пользователей */
SELECT COUNT(DISTINCT visitor_id) AS unique_visitors_count
FROM sessions;

/* Каналы, приводящие пользователей по дням (визиты) */
SELECT
    source,
    COUNT(*) AS visits_count,
    DATE_TRUNC('day', visit_date) AS visit_date
FROM sessions
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

/* Результирующая таблица дашборда dashboard_final */
WITH last_paid_sessions AS (
    SELECT
        s.visitor_id,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.amount,
        l.closing_reason,
        l.status_id,
        DATE(s.visit_date) AS visit_date,
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
),

lpc AS (
    SELECT *
    FROM last_paid_sessions
    WHERE rn = 1
),

traffic AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(visitor_id) AS visitors_count
    FROM lpc
    GROUP BY 1, 2, 3, 4
),

conversions AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(lead_id) AS leads_count,
        COUNT(lead_id) FILTER (
            WHERE closing_reason = 'Успешно реализовано'
            OR status_id = 142
        ) AS purchases_count,
        SUM(amount) FILTER (
            WHERE closing_reason = 'Успешно реализовано'
            OR status_id = 142
        ) AS revenue
    FROM lpc
    GROUP BY 1, 2, 3, 4
),

costs_raw AS (
    SELECT
        DATE(campaign_date) AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    FROM vk_ads
    UNION ALL
    SELECT
        DATE(campaign_date) AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    FROM ya_ads
),

costs AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM costs_raw
    GROUP BY 1, 2, 3, 4
)

SELECT
    t.visit_date,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    t.visitors_count,
    c.leads_count,
    c.purchases_count,
    c.revenue,
    co.total_cost
FROM traffic AS t
LEFT JOIN conversions AS c
    ON
        t.visit_date = c.visit_date
        AND t.utm_source = c.utm_source
        AND t.utm_medium = c.utm_medium
        AND t.utm_campaign = c.utm_campaign
LEFT JOIN costs AS co
    ON
        t.visit_date = co.visit_date
        AND t.utm_source = co.utm_source
        AND t.utm_medium = co.utm_medium
        AND t.utm_campaign = co.utm_campaign;

/* Расчет основных метрик: cpu, cpl, cppu, roi с агрегацией по utm_source */
SELECT
    utm_source,
    SUM(visitors_count) AS visitors_count,
    SUM(leads_count) AS leads_count,
    SUM(purchases_count) AS purchases_count,
    SUM(revenue) AS revenue,
    SUM(total_cost) AS total_cost,
    ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0), 2) AS cpu,
    ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0), 2) AS cpl,
    ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0), 2) AS cppu,
    ROUND((SUM(revenue) - SUM(total_cost)) / NULLIF(SUM(total_cost), 0) * 100, 2) AS roi
FROM dashboard_final
GROUP BY utm_source
ORDER BY roi DESC NULLS LAST;

/* Расчет основных метрик: cpu, cpl, cppu, roi с агрегацией по utm_source, utm_medium, utm_campaign */
SELECT
    utm_source,
    utm_medium,
    utm_campaign,
    SUM(visitors_count) AS visitors_count,
    SUM(leads_count) AS leads_count,
    SUM(purchases_count) AS purchases_count,
    SUM(revenue) AS revenue,
    SUM(total_cost) AS total_cost,
    ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0), 2) AS cpu,
    ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0), 2) AS cpl,
    ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0), 2) AS cppu,
    ROUND(
        (SUM(revenue) - SUM(total_cost)) / NULLIF(SUM(total_cost), 0) * 100,
        2
    ) AS roi
FROM dashboard_final
GROUP BY
    utm_source,
    utm_medium,
    utm_campaign
ORDER BY
    roi DESC NULLS LAST;
