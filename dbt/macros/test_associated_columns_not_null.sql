-- test the number of rows that are null in associated columns.
-- For instance if fever = yes then one of the associated
-- column is fever_duration.
{% macro test_associated_columns_not_null(model, column_name, col_value, associated_columns, name) %}

select
  count(*)
from
  {{model}}
where
  {{column_name}} = {{col_value}}
  and (
    {% for col in associated_columns %}
      {{col}} is null
      {% if not loop.last %}
        or
      {% endif %}
    {% endfor %}
  )

{% endmacro %}