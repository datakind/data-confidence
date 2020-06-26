{{ config(materialized='table') }}

with source_data as (

    select * from pregnancy_follow_up

)

select *
from source_data