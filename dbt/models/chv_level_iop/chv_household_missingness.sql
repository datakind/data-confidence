-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("household_missingness_relation_prefix") %}
{% set household_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set household_relations = filter_by_word(list_to_filter=household_relations, word_to_filter="visit") %}
{% set household_relations = filter_by_list(list_to_filter=household_relations, list_of_words=var("household_missingness_cols")) %}

{% set household_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set household_column_names = filter_by_word(list_to_filter=household_column_names, word_to_filter="visit") %}
{% set household_column_names = filter_by_list(list_to_filter=household_column_names, list_of_words=var("household_missingness_cols")) %}

{% for household_relation in household_relations %}
{% set household_column = get_column_name(relation=household_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ household_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ household_column }} IS NULL THEN 1 END AS {{ household_column }}_household_missing
    FROM {{ household_relation }}
),
{% endfor %}

household_final as ( 
    SELECT
    household.uuid, 
    household.chv_area_id,
    {% for household_column in household_column_names %}
    {{ household_column }}_household_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('household') }} household
    {% for household_column in household_column_names %}
    LEFT JOIN {{ household_column }}_missing_data ON household.uuid = {{ household_column }}_missing_data.uuid
    {% endfor %}
)

select * from household_final