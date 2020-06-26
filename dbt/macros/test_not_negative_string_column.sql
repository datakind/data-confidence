-- test to make sure that columns of string type that
-- represents an integer is not negative.
{% macro test_not_negative_string_column(model, column_name, name, description) %}

select
  count(*)
from
  {{model}}
where
  {{column_name}}::varchar like '-%'

{% endmacro %}