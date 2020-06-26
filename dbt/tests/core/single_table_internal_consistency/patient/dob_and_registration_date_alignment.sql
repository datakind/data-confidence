-- From Nat: warn on situations where dob and registration month+day are the same
-- Notebook: NS-4.0-Date of birth Inconsitencies.ipynb

{{ config(severity='warn') }}

with patient_dates as (
	SELECT uuid, date_of_birth,
	TO_DATE(date_of_birth, 'YYYY-MM-DD') as clean_dob,
	EXTRACT(month from TO_DATE(date_of_birth, 'YYYY-MM-DD')) as dob_month,
	EXTRACT(day from TO_DATE(date_of_birth, 'YYYY-MM-DD')) as dob_day,
	TO_DATE(reported, 'YYYY-MM-DD') as clean_reported_date,
	EXTRACT(month from TO_DATE(reported, 'YYYY-MM-DD')) as reported_month,
	EXTRACT(day from TO_DATE(reported, 'YYYY-MM-DD')) as reported_day
	
	FROM  {{ ref('patient') }}
)

select uuid
from patient_dates
where dob_month = reported_month
and dob_day = reported_day
and clean_dob != clean_reported_date

