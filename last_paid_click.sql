WITH paid_sessions AS (
    SELECT
        visitor_id,
        visit_date,
        source,
        medium,
        campaign
    FROM sessions
    WHERE medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

leads_with_attribution AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id::bigint AS lead_id,
        l.created_at::timestamp AS created_at,
        l.amount::numeric AS amount,
        l.closing_reason::varchar AS closing_reason,
        l.status_id::bigint AS status_id,
        ROW_NUMBER() OVER (
            PARTITION BY l.lead_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM leads AS l
    INNER JOIN paid_sessions AS s
        ON
            l.visitor_id = s.visitor_id
            AND l.created_at >= s.visit_date
),

visitors_without_leads AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        NULL::bigint AS lead_id,
        NULL::timestamp AS created_at,
        NULL::numeric AS amount,
        NULL::varchar AS closing_reason,
        NULL::bigint AS status_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM paid_sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE l.visitor_id IS NULL
)

SELECT
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM leads_with_attribution
WHERE rn = 1
UNION ALL
SELECT
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM visitors_without_leads
WHERE rn = 1
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
