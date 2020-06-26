{{ config(materialized='table') }}

with source_data as (

    select * from immunization

)

select *
from source_data