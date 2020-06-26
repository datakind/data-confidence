-- Build table to assess timing of follow-ups after an assessment
-- Notebook: MT-Understanding Timing of Follow-Ups after Assessments (Feb Data)
{{ config(materialized='table') }}

with source_data as (
Select c.*,
             b.prev_reported,
             b.rank_followup_visits,
             (DATE_PART('day', to_timestamp(c.reported_y, 'YYYY-MM-DD hh24:mi:ss') - to_timestamp(b.prev_reported, 'YYYY-MM-DD hh24:mi:ss')) * 24 + 
               DATE_PART('hour', to_timestamp(c.reported_y, 'YYYY-MM-DD hh24:mi:ss') - to_timestamp(b.prev_reported, 'YYYY-MM-DD hh24:mi:ss'))) * 60 +
               DATE_PART('minute', to_timestamp(c.reported_y, 'YYYY-MM-DD hh24:mi:ss') - to_timestamp(b.prev_reported, 'YYYY-MM-DD hh24:mi:ss')) as datediff_followup_min,
             b.prev_patient_condition,
             CASE WHEN b.prev_patient_condition is not NULL then CONCAT(b.prev_patient_condition,' to ',c.condition)
                  ELSE b.prev_patient_condition END as flow_pat_condition,
             b.prev_fever,
             CASE WHEN b.prev_fever is not NULL then CONCAT(b.prev_fever,' to ',c.fever)
                  ELSE b.prev_fever END as flow_fever,
             b.prev_convulsions,
             CASE WHEN b.prev_convulsions is not NULL then CONCAT(b.prev_convulsions,' to ',c.convulsions)
                  ELSE b.prev_convulsions END as flow_convulsions,
             b.prev_fast_breathing,
             CASE WHEN b.prev_fast_breathing is not NULL then CONCAT(b.prev_fast_breathing,' to ',c.fast_breathing)
                  ELSE b.prev_fast_breathing END as flow_fast_breathing
             
             
FROM (Select a.uuid,
       a.reported_by,
       a.reported_by_parent,
       a.form,
       a.reported as reported_x,
       a.patient_uuid,
       a.source,
       f.source_id,
       f.reported as reported_y,
       f.condition,
       f.follow_up_method,
       f.c_follow_up_message,
       f.fever,
       f.convulsions,
       f.fast_breathing,
       f.next_follow_up,
       f.unable_to_feed,
       f.chest_indrawing,
       f.muac_strap_color,
       f.unusually_sleepy,
       f.vomits_everything,
       f.r_danger_sign_present,
       f.c_patient_age,
       f.r_followup_instructions,
       f.patient_gender,
       f.patient_age_in_days,
       f.patient_age_in_years,
       f.patient_age_in_months,
       CASE WHEN f.had_follow_up is NULL then 0 else f.had_follow_up END as had_follow_up
FROM {{ ref('assessment') }} a
LEFT JOIN (Select *, 
           1 as had_follow_up
    FROM {{ ref('assessment_follow_up') }}) f 
ON f.source_id = a.uuid
ORDER BY a.uuid, f.reported) c
LEFT JOIN (
Select x.uuid, x.reported_y,
LAG(x.reported_y) OVER(ORDER BY x.uuid) AS prev_reported,
RANK () OVER (PARTITION BY x.uuid ORDER BY x.reported_y) rank_followup_visits,
LAG(x.condition) OVER(ORDER BY x.uuid) AS prev_patient_condition,
LAG(x.fever) OVER(ORDER BY x.uuid) AS prev_fever,
LAG(x.convulsions) OVER(ORDER BY x.uuid) AS prev_convulsions,
LAG(x.fast_breathing) OVER(ORDER BY x.uuid) AS prev_fast_breathing

FROM (SELECT a.uuid, f.reported as reported_y, f.condition, f.fever, f.convulsions, f.fast_breathing
      FROM {{ ref('assessment') }} a
      LEFT JOIN {{ ref('assessment_follow_up') }} f
        ON f.source_id = a.uuid
      ORDER BY a.uuid, f.reported) x
) b
ON c.uuid = b.uuid AND c.reported_y = b.reported_y
)

select *
from source_data