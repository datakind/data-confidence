-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("patient_missingness_relation_prefix") %}
{% set patient_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set patient_relations = filter_by_list(list_to_filter=patient_relations, list_of_words=var("patient_missingness_cols")) %}

{% set patient_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set patient_column_names = filter_by_list(list_to_filter=patient_column_names, list_of_words=var("patient_missingness_cols")) %}

{% for patient_relation in patient_relations %}
{% set patient_column = get_column_name(relation=patient_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ patient_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ patient_column }} IS NULL THEN 1 END AS {{ patient_column }}_patient_missing
    FROM {{ patient_relation }}
),
{% endfor %}

patient_final as ( 
    SELECT
    patient.uuid, 
    patient.chv_area_id,
    {% for patient_column in patient_column_names %}
    {{ patient_column }}_patient_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('patient') }} patient
    {% for patient_column in patient_column_names %}
    LEFT JOIN {{ patient_column }}_missing_data ON patient.uuid = {{ patient_column }}_missing_data.uuid
    {% endfor %}
)

select * from patient_final