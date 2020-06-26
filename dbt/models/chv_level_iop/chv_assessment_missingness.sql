-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_missingness_prefix = var("assessment_missingness_relation_prefix") %}
{% set orig_assessment_missingness_relations = get_relations(schema=schema, relation_prefix=relation_missingness_prefix) %}
{% set assessment_missingness_relations = filter_by_word(list_to_filter=orig_assessment_missingness_relations, word_to_filter="follow_up") %}
{% set assessment_missingness_relations = filter_by_list(list_to_filter=assessment_missingness_relations, list_of_words=var("assessment_missingness_cols")) %}


{% set orig_assessment_missingness_column_names = get_column_names(schema=schema, relation_prefix=relation_missingness_prefix) %}
{% set assessment_missingness_column_names = filter_by_word(list_to_filter=orig_assessment_missingness_column_names, word_to_filter="follow_up") %}
{% set assessment_missingness_column_names = filter_by_list(list_to_filter=assessment_missingness_column_names, list_of_words=var("assessment_missingness_cols")) %}


{% for assessment_relation in assessment_missingness_relations %}
{% set assessment_column = get_column_name(relation=assessment_relation, schema=schema, relation_prefix=relation_missingness_prefix) %}
{% if loop.first %}with {% endif %}
{{ assessment_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ assessment_column }} IS NULL THEN 1 END AS {{ assessment_column }}_assessment_missing
    FROM {{ assessment_relation }}
), 
{% endfor %}

assessment_final as ( 
    SELECT
    assessment.uuid, 
    assessment.reported_by,
    {% for assessment_column in assessment_missingness_column_names %}
    {{ assessment_column }}_assessment_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('assessment') }} assessment
    {% for assessment_column in assessment_missingness_column_names %}
    LEFT JOIN {{ assessment_column }}_missing_data ON assessment.uuid = {{ assessment_column }}_missing_data.uuid
    {% endfor %}
)

select * from assessment_final