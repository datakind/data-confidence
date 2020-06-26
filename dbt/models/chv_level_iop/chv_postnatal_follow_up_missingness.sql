-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("postnatal_follow_up_missingness_relation_prefix") %}
{% set postnatal_follow_up_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set postnatal_follow_up_relations = filter_by_list(list_to_filter=postnatal_follow_up_relations, list_of_words=var("postnatal_follow_up_missingness_cols")) %}

{% set postnatal_follow_up_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set postnatal_follow_up_column_names = filter_by_list(list_to_filter=postnatal_follow_up_column_names, list_of_words=var("postnatal_follow_up_missingness_cols")) %}

{% for postnatal_follow_up_relation in postnatal_follow_up_relations %}
{% set postnatal_follow_up_column = get_column_name(relation=postnatal_follow_up_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ postnatal_follow_up_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ postnatal_follow_up_column }} IS NULL THEN 1 END AS {{ postnatal_follow_up_column }}_postnatal_follow_up_missing
    FROM {{ postnatal_follow_up_relation }}
),
{% endfor %}

postnatal_follow_up_final as ( 
    SELECT
    postnatal_follow_up.uuid, 
    postnatal_follow_up.reported_by,
    {% for postnatal_follow_up_column in postnatal_follow_up_column_names %}
    {{ postnatal_follow_up_column }}_postnatal_follow_up_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('postnatal_follow_up') }} postnatal_follow_up
    {% for postnatal_follow_up_column in postnatal_follow_up_column_names %}
    LEFT JOIN {{ postnatal_follow_up_column }}_missing_data ON postnatal_follow_up.uuid = {{ postnatal_follow_up_column }}_missing_data.uuid
    {% endfor %}
)

select * from postnatal_follow_up_final