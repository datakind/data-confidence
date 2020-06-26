{{ config(materialized='table') }}

with source_data as (

    select * from chv

)

select *
from source_data