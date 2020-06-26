-- From Melinda: Do assessment and corresponding follow-ups have the same patient?
-- Notebook: MT-Error Detection - Assessments and follow-ups do not have the same the patient listed
with assessments_and_follow_ups as (
	select 
		afu.uuid as assessment_follow_up_uuid,
		afu.patient_uuid as asseement_follow_up_patient_uuid,
		a.uuid as assessment_uuid,
		a.patient_uuid as assessment_patient_uuid
	from  {{ ref('assessment_follow_up') }} afu
	left join  {{ ref('assessment') }} a
	on a.uuid = afu.source_id
)

select assessment_follow_up_uuid
from assessments_and_follow_ups
where asseement_follow_up_patient_uuid != assessment_patient_uuid

