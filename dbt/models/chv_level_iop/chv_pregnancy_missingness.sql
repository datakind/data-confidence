-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("pregnancy_missingness_relation_prefix") %}
{% set pregnancy_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set pregnancy_relations = filter_by_word(list_to_filter=pregnancy_relations, word_to_filter="follow_up") %}
{% set pregnancy_relations = filter_by_list(list_to_filter=pregnancy_relations, list_of_words=var("pregnancy_missingness_cols")) %}

{% set pregnancy_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set pregnancy_column_names = filter_by_word(list_to_filter=pregnancy_column_names, word_to_filter="follow_up") %}
{% set pregnancy_column_names = filter_by_list(list_to_filter=pregnancy_column_names, list_of_words=var("pregnancy_missingness_cols")) %}

{% for pregnancy_relation in pregnancy_relations %}
{% set pregnancy_column = get_column_name(relation=pregnancy_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ pregnancy_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ pregnancy_column }} IS NULL THEN 1 END AS {{ pregnancy_column }}_pregnancy_missing
    FROM {{ pregnancy_relation }}
),
{% endfor %}

pregnancy_final as ( 
    SELECT
    pregnancy.uuid, 
    pregnancy.reported_by,
    {% for pregnancy_column in pregnancy_column_names %}
    {{ pregnancy_column }}_pregnancy_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('pregnancy') }} pregnancy
    {% for pregnancy_column in pregnancy_column_names %}
    LEFT JOIN {{ pregnancy_column }}_missing_data ON pregnancy.uuid = {{ pregnancy_column }}_missing_data.uuid
    {% endfor %}
)

select * from pregnancy_final