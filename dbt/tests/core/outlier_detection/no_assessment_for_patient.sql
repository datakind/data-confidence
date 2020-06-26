-- no assessment for patient who has been reported over 3 years ago.
-- Notebook: LT-Step-03-IoP-Findings.ipynb (Assessment Data Section 2 and 4)
with patient_no_assessment as (

    select 
    patient.uuid, 
    patient.reported as patient_reported
    from {{ ref('patient') }} patient 
    left join {{ ref('assessment') }} assessment
    on patient.uuid = assessment.patient_uuid
    where assessment.patient_uuid is null
)

select * 
from patient_no_assessment pna
where (CURRENT_DATE::date - pna.patient_reported::date) >= 1095
