{{ config(materialized='table') }}

with source_data as (

    select * from delivery

)

select *
from source_data