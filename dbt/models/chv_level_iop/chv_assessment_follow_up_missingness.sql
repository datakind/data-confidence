-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_missingness_prefix = var("followup_missingness_relation_prefix") %}
{% set assessment_followup_missingness_relations = get_relations(schema=schema, relation_prefix=relation_missingness_prefix) %}
{% set assessment_followup_missingness_relations = filter_by_list(list_to_filter=assessment_followup_missingness_relations, list_of_words=var("followup_missingness_cols")) %}

{% set assessment_followup_missingness_column_names = get_column_names(schema=schema, relation_prefix=relation_missingness_prefix) %}
{% set assessment_followup_missingness_column_names = filter_by_list(list_to_filter=assessment_followup_missingness_column_names, list_of_words=var("followup_missingness_cols")) %}

{% for assessment_followup_relation in assessment_followup_missingness_relations %}
{% set assessment_followup_column = get_column_name(relation=assessment_followup_relation, schema=schema, relation_prefix=relation_missingness_prefix) %}
{% if loop.first %}with {% endif %}
{{ assessment_followup_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ assessment_followup_column }} IS NULL THEN 1 END AS {{ assessment_followup_column }}_assessment_followup_missing
    FROM {{ assessment_followup_relation }}
), 
{% endfor %}

assessment_followup_final as ( 
    SELECT
    assessment_followup.uuid, 
    assessment_followup.reported_by,
    {% for assessment_followup_column in assessment_followup_missingness_column_names %}
    {{ assessment_followup_column }}_assessment_followup_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('assessment_follow_up') }} assessment_followup
    {% for assessment_followup_column in assessment_followup_missingness_column_names %}
    LEFT JOIN {{ assessment_followup_column }}_missing_data ON assessment_followup.uuid = {{ assessment_followup_column }}_missing_data.uuid
    {% endfor %}
)

select * from assessment_followup_final