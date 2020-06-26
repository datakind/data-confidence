-- Mismatched sex columns from assessment and patient tables.
-- Notebook: LT-Step-03-IoP-Findings.ipynb (Assessment Data Section 3)
with mismatched_sex as (
    select 
    patient.uuid as to_id, 
    assessment.uuid as from_uuid,
    assessment.sex as assessment_sex,
    patient.sex as patient_sex
    from {{ ref('assessment') }} assessment 
    join {{ ref('patient') }} patient
    on assessment.patient_uuid = patient.uuid 
    where assessment.sex is not null 
    and patient.sex is not null
    and assessment.sex != patient.sex
)

select * 
from mismatched_sex