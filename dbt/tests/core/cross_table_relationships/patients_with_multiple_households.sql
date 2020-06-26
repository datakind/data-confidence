-- patients that have multiple households assigned to them.

with source_data as (
    select
      h.uuid household_id,
      p.uuid patient_id
    from
      {{ ref('household') }} h
      full outer join {{ ref('patient') }} p on p.parent_uuid = h.uuid
)

select
  patient_id,
  count(*)
from
  source_data
where
  patient_id is not null
  and household_id is not null
group by
  patient_id
having
  count(*) > 1