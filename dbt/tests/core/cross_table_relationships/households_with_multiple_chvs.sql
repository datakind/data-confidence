-- Households that have multiple chvs assigned to them.
with source_data as (
    select
      c.chv_uuid chv_id,
      h.uuid household_id
    from
      {{ ref('chv') }} c
      full outer join {{ ref('household') }} h on h.chv_area_id = c.cu_uuid
)

select
  household_id,
  count(*) total_chvs
from
  source_data
where
  chv_id is not null
  and household_id is not null
group by
  household_id
having
  count(*) > 1