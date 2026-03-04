WITH last_paid_sessions AS (
    SELECT
        s.visitor_id,
        s.source,
        s.medium,
        s.campaign,
        l.lead_id,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER()
            OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC) AS rn,
        DATE(s.visit_date) AS visit_date
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON
            s.visitor_id = l.visitor_id
            AND s.visit_date <= l.created_at
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

spent AS (
    SELECT
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY
        DATE(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
    UNION ALL
    SELECT
        DATE(campaign_date) AS campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY
        DATE(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
)

SELECT
    lps.visit_date,
    lps.source AS utm_source,
    lps.medium AS utm_medium,
    lps.campaign AS utm_campaign,
    sp.total_cost,
    COUNT(lps.visitor_id) AS visitors_count,
    COUNT(lps.lead_id) AS leads_count,
    COUNT(lps.lead_id) FILTER (
        WHERE lps.closing_reason = 'Успешно реализовано' OR lps.status_id = 142
    ) AS purchases_count,
    SUM(lps.amount) FILTER (
        WHERE lps.closing_reason = 'Успешно реализовано' OR lps.status_id = 142
    ) AS revenue
FROM last_paid_sessions AS lps
LEFT JOIN spent AS sp
    ON
        lps.visit_date = sp.campaign_date
        AND lps.source = sp.utm_source
        AND lps.medium = sp.utm_medium
        AND lps.campaign = sp.utm_campaign
WHERE lps.rn = 1
GROUP BY
    lps.visit_date,
    lps.source,
    lps.medium,
    lps.campaign,
    sp.total_cost
ORDER BY
    revenue DESC NULLS LAST,
    lps.visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
