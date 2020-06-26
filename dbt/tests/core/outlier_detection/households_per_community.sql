with households_per_community_counts as (

  select
    chv_area_id community_id,
    count(*) total_households
  from
    {{ ref('household') }}
  group by
    chv_area_id

),

statistics as (

  select
    (avg(total_households) - (10 * stddev(total_households))) minimum,
    (avg(total_households) + (10 * stddev(total_households))) maximum
  from
    households_per_community_counts

)


select
  *
from
  households_per_community_counts
where
  total_households <= (select minimum from statistics)
  or total_households >= (select maximum from statistics)