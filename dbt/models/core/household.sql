{{ config(materialized='table') }}

with source_data as (

    select * from household

)

select *
from source_data