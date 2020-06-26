with assessments_for_adults as (
    Select a.*,
        (CASE WHEN a.age > 5 then 1 else 0 end) as assessmentgiven_over5
    FROM {{ ref('assessment') }} a
)

Select *
From assessments_for_adults
WHERE assessmentgiven_over5 = 1