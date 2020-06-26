-- Flag follow-ups occuring within 30 min of previous follow-up that are linked to same assessment
-- Notebook: MT-Understanding Timing of Follow-Ups after Assessments (Feb Data)
with followups_lessthan30min as (
    Select a.*,
        (CASE WHEN a.datediff_followup_min <= 30 then 1 else 0 end) as followup_timing_warning
    FROM {{ ref('assessment_followup_timing') }} a
)

Select *
From followups_lessthan30min
WHERE followup_timing_warning = 1