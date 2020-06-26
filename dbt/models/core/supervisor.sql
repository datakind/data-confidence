{{ config(materialized='table') }}

with source_data as (

    select * from supervisor

)

select *
from source_data