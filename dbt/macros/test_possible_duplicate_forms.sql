-- test to check if a patient was reported more than once in an hour.
-- If so flag as possible duplicate form.
{% macro test_possible_duplicate_forms(model) %}

with records_per_patient_hour as (
select 
	date_trunc('hour', reported::timestamp) as date_hour,
	patient_uuid as patient_uuid_to_flag, 
	count(uuid) as number_of_records
FROM {{ model }}
group by 1, 2
), 

possible_duplicate_combinations as (
select *
from records_per_patient_hour
where number_of_records > 1
)

select count(*)
from possible_duplicate_combinations pdc
left join {{ model }} m
on date_trunc('hour', m.reported::timestamp) = pdc.date_hour
and m.patient_uuid = pdc.patient_uuid_to_flag

{% endmacro %}