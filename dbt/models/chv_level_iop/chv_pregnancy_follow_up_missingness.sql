-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("pregnancy_follow_up_missingness_relation_prefix") %}
{% set pregnancy_follow_up_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set pregnancy_follow_up_relations = filter_by_list(list_to_filter=pregnancy_follow_up_relations, list_of_words=var("pregnancy_follow_up_missingness_cols")) %}

{% set pregnancy_follow_up_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set pregnancy_follow_up_column_names = filter_by_list(list_to_filter=pregnancy_follow_up_column_names, list_of_words=var("pregnancy_follow_up_missingness_cols")) %}

{% for pregnancy_follow_up_relation in pregnancy_follow_up_relations %}
{% set pregnancy_follow_up_column = get_column_name(relation=pregnancy_follow_up_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ pregnancy_follow_up_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ pregnancy_follow_up_column }} IS NULL THEN 1 END AS {{ pregnancy_follow_up_column }}_pregnancy_follow_up_missing
    FROM {{ pregnancy_follow_up_relation }}
),
{% endfor %}

pregnancy_follow_up_final as ( 
    SELECT
    pregnancy_follow_up.uuid, 
    pregnancy.reported_by,
    {% for pregnancy_follow_up_column in pregnancy_follow_up_column_names %}
    {{ pregnancy_follow_up_column }}_pregnancy_follow_up_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('pregnancy_follow_up') }} pregnancy_follow_up
    JOIN {{ ref('pregnancy') }} pregnancy
    ON pregnancy_follow_up.pregnancy_uuid = pregnancy.uuid
    {% for pregnancy_follow_up_column in pregnancy_follow_up_column_names %}
    LEFT JOIN {{ pregnancy_follow_up_column }}_missing_data ON pregnancy_follow_up.uuid = {{ pregnancy_follow_up_column }}_missing_data.uuid
    {% endfor %}
)

select * from pregnancy_follow_up_final