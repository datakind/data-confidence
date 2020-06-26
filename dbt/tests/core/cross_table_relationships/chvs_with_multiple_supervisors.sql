-- Get chvs that have more than one supervisor.
with supervisors_and_chvs as (
  select
    c.chv_uuid chv_id,
    s.cha_uuid supervisor_id
  from
    {{ ref('chv') }} c
    left join {{ ref('supervisor') }} s on s.cha_uuid = c.cha_uuid
)

select
  chv_id,
  count(*) total_supervisors
from
  supervisors_and_chvs
where
  supervisor_id is not null
group by
  chv_id
having
  count(*) > 1