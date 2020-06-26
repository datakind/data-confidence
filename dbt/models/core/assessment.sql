{{ config(materialized='table') }}

with source_data as (

    select a.*,
    --standardizing columns
    (case when a.fast_breathing in ('true','yes') then 'yes' else 'no' end) as fast_breathing_cleaned,
    (case when a.r_has_danger_sign = 'yes' then 'yes' else 'no' end) as r_has_danger_sign_cleaned,
    (case when a.mrdt_result = 'positive' then 'yes'
          when a.mrdt_result = 'negative' then 'no'
          else 'not_done' end) as mrdt_result_cleaned,
    (case when a.c_has_malnutrition = 'yes' then 'yes' else 'no' end) as c_has_malnutrition_cleaned, 
    (case when a.malaria_al_treatment_given = 'yes' then 'yes' else 'no' end) as malaria_al_treatment_given_cleaned,
    (case when a.diarrhoea_ors_treatment_given = 'yes' then 'yes' else 'no' end) as diarrhoea_ors_treatment_given_cleaned,
    (case when a.diarrhoea_zinc_treatment_given = 'yes' then 'yes' else 'no' end) as diarrhoea_zinc_treatment_given_cleaned,
    (case when a.malnutrition_treatment_given = 'yes' then 'yes' else 'no' end) as malnutrition_treatment_given_cleaned,
    (case when a.fever_treatment_given = 'yes' then 'yes' else 'no' end) as fever_treatment_given_cleaned,
    (case when diarrhoea_duration in ('1','1.0','2','2.0','2_days_or_less') THEN '2_days_or_less'
          when diarrhoea_duration in ('3','3.0','4','4.0','5','5.0','6','6.0','3_to_6_days') THEN '3_to_6_days'
          when diarrhoea_duration in ('7','7.0') THEN '7_days'
          when diarrhoea_duration in ('14','14.0','more_than_14_days') THEN '14_days_or_more'
          ELSE diarrhoea_duration END) as diarrhoea_duration_cleaned,
    --cleaning up age (any child under 1 is an age of 0)
    CAST((CASE WHEN b.age LIKE '%days%' OR b.age LIKE '%month%' then '0' else b.age end) as int) as age

    from assessment a 
    LEFT JOIN (Select uuid,
        REPLACE(c_patient_age,' years old','') as age
        FROM assessment ) b 
        ON b.uuid = a.uuid

)

select *
from source_data