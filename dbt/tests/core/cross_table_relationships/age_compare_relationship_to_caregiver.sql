-- calculated age does not make sense with relationship to caregiver field.
-- Notebook: LT-Step-03-IoP-Findings.ipynb (Followup Data Section 3)
with wrong_age_relationship_to_caregiver_data as (
    select 
    patient.uuid,
    c_patient_age, 
    patient.date_of_birth as patient_dob, 
    patient.relationship_to_primary_caregiver 
    from {{ ref('assessment') }} assessment
    join {{ ref('patient') }} patient
    on assessment.patient_uuid = patient.uuid
    where
    -- age/spouse discrepancy
    ((c_patient_age like '%year%' and split_part(c_patient_age, ' ' , 1)::int < 18)
    or c_patient_age like '%day%' or c_patient_age like '%month%')
    and patient.relationship_to_primary_caregiver = 'spouse'
)

select * from 
wrong_age_relationship_to_caregiver_data