{{ config(materialized='table') }}

with source_data as (

    select * from patient

)

select *
from source_data