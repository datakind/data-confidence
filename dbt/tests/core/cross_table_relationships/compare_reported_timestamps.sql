-- Assessment reported before patient was reported.
-- Notebook: LT-Step-03-IoP-Findings.ipynb (Assessment Data Section 5)
with bad_reported_data as (
    select
    patient.uuid as to_id,
    assessment.uuid as from_uuid,
    assessment.reported as assessment_reported_date, 
    patient.reported as patient_reported_date,
    (assessment.reported::date - patient.reported::date) as delta_time 
    from {{ ref('assessment') }} assessment 
    join {{ ref('patient') }} patient
    on assessment.patient_uuid = patient.uuid 
    where (assessment.reported::date - patient.reported::date) < 0
)

select * 
from bad_reported_data
