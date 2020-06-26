{{ config(materialized='table') }}

with source_data as (

    select * from pregnancy

)

select *
from source_data