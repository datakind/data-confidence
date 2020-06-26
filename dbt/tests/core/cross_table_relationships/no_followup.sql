-- no follow up for a patient who is supposed to have a follow up.
-- Notebook: LT-Step-03-IoP-Findings.ipynb (Followup Data Section 1)
with no_followup as (
    select 
    assessment.uuid,
    assessment.patient_uuid,
    assessment.r_followup_instructions, 
    assessment.reported as assessment_reported_date, 
    (current_date::date - assessment.reported::date) as delta_time
    from {{ ref('assessment') }} assessment
    left join {{ ref('assessment_follow_up') }} follow_up
    on assessment.patient_uuid = follow_up.patient_uuid
    where assessment.r_followup_instructions like '%3 days%'
    and follow_up.patient_uuid is null 
    and (current_date::date - assessment.reported::date) > 3
)

select * 
from no_followup 