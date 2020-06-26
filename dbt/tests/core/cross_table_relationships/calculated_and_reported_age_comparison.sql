-- calculated age does not match patient date of birth and when assessment is conducted.
-- Notebook: LT-Step-03-IoP-Findings.ipynb (Followup Data Section 1)
with wrong_calculated_or_reported_age as (
    select 
    patient.uuid as to_id,
    assessment.uuid as from_uuid, 
    c_patient_age, 
    assessment.reported as assessment_reported_date, 
    patient.date_of_birth as patient_dob, 
    split_part(c_patient_age, ' ' , 1 )::int as calculated_age, 
    extract(year from age(assessment.reported::date, patient.date_of_birth::date)) as reported_age_year,
    assessment.reported::date - patient.date_of_birth::date as reported_age_day
    from {{ ref('assessment') }} assessment
    join {{ ref('patient') }} patient
    on assessment.patient_uuid = patient.uuid
    where 
    (c_patient_age like '%year%' or c_patient_age like '%day%')
    and 
    (
    (
    split_part(c_patient_age, ' ' , 1)::int != 
        ( 
        case when c_patient_age like '%day%'
        then assessment.reported::date - patient.date_of_birth::date
        else 
        extract(year from age(assessment.reported::date, patient.date_of_birth::date))
        end
        )
    )
    or 
    (split_part(c_patient_age, ' ' , 1)::int < 0)
    )
)

select * 
from wrong_calculated_or_reported_age