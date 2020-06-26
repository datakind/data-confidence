-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{% set schema = var("dbt_schema") %}
{% set relation_prefix = var("delivery_missingness_relation_prefix") %}
{% set delivery_relations = get_relations(schema=schema, relation_prefix=relation_prefix) %}
{% set delivery_relations = filter_by_list(list_to_filter=delivery_relations, list_of_words=var("delivery_missingness_cols")) %}

{% set delivery_column_names = get_column_names(schema=schema, relation_prefix=relation_prefix) %}
{% set delivery_column_names = filter_by_list(list_to_filter=delivery_column_names, list_of_words=var("delivery_missingness_cols")) %}

{% for delivery_relation in delivery_relations %}
{% set delivery_column = get_column_name(relation=delivery_relation, schema=schema, relation_prefix=relation_prefix) %}
{% if loop.first %}with {% endif %}
{{ delivery_column }}_missing_data as (
    SELECT uuid, CASE WHEN {{ delivery_column }} IS NULL THEN 1 END AS {{ delivery_column }}_delivery_missing
    FROM {{ delivery_relation }}
),
{% endfor %}

delivery_final as ( 
    SELECT
    delivery.uuid, 
    delivery.reported_by,
    {% for delivery_column in delivery_column_names %}
    {{ delivery_column }}_delivery_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('delivery') }} delivery
    {% for delivery_column in delivery_column_names %}
    LEFT JOIN {{ delivery_column }}_missing_data ON delivery.uuid = {{ delivery_column }}_missing_data.uuid
    {% endfor %}
)

select * from delivery_final