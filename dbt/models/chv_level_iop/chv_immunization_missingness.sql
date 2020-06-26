-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("immunization_missingness_relation_prefix") %}
{% set immunization_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set immunization_relations = filter_by_list(list_to_filter=immunization_relations, list_of_words=var("immunization_missingness_cols")) %}

{% set immunization_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set immunization_column_names = filter_by_list(list_to_filter=immunization_column_names, list_of_words=var("immunization_missingness_cols")) %}

{% for immunization_relation in immunization_relations %}
{% set immunization_column = get_column_name(relation=immunization_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ immunization_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ immunization_column }} IS NULL THEN 1 END AS {{ immunization_column }}_immunization_missing
    FROM {{ immunization_relation }}
),
{% endfor %}

immunization_final as ( 
    SELECT
    immunization.uuid, 
    immunization.reported_by,
    {% for immunization_column in immunization_column_names %}
    {{ immunization_column }}_immunization_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('immunization') }} immunization
    {% for immunization_column in immunization_column_names %}
    LEFT JOIN {{ immunization_column }}_missing_data ON immunization.uuid = {{ immunization_column }}_missing_data.uuid
    {% endfor %}
)

select * from immunization_final