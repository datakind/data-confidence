{{ config(materialized='table') }}

with source_data as (

    select * from assessment_follow_up

)

select *
from source_data