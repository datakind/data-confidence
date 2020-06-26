-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("household_visit_missingness_relation_prefix") %}
{% set household_visit_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set household_visit_relations = filter_by_list(list_to_filter=household_visit_relations, list_of_words=var("household_visit_missingness_cols")) %}

{% set household_visit_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set household_visit_column_names = filter_by_list(list_to_filter=household_visit_column_names, list_of_words=var("household_visit_missingness_cols")) %}

{% for household_visit_relation in household_visit_relations %}
{% set household_visit_column = get_column_name(relation=household_visit_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ household_visit_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ household_visit_column }} IS NULL THEN 1 END AS {{ household_visit_column }}_household_visit_missing
    FROM {{ household_visit_relation }}
),
{% endfor %}

household_visit_final as ( 
    SELECT
    household_visit.uuid, 
    household_visit.reported_by,
    {% for household_visit_column in household_visit_column_names %}
    {{ household_visit_column }}_household_visit_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('household_visit') }} household_visit
    {% for household_visit_column in household_visit_column_names %}
    LEFT JOIN {{ household_visit_column }}_missing_data ON household_visit.uuid = {{ household_visit_column }}_missing_data.uuid
    {% endfor %}
)

select * from household_visit_final