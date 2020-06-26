{{ config(materialized='table') }}

with source_data as (

    select * from household_visit

)

select *
from source_data