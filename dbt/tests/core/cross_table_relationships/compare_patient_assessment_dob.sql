-- Mismatched date of birth columns from assessment and patient tables.
-- Notebook: LT-Step-03-IoP-Findings.ipynb (Assessment Data Section 3)
with mismatched_dob as (
    select 
    patient.uuid as to_id,
    assessment.uuid as from_uuid,
    assessment.date_of_birth as assessment_dob,
    patient.date_of_birth as patient_dob
    from {{ ref('assessment') }} assessment 
    join {{ ref('patient') }} patient
    on assessment.patient_uuid = patient.uuid 
    where assessment.date_of_birth is not null 
    and patient.date_of_birth is not null
    and assessment.date_of_birth != patient.date_of_birth
)

select * 
from mismatched_dob