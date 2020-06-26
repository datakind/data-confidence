-- Notebook: LT-Step-04-CHV-Level-Findings.ipynb
{{ config(materialized='view') }}

{% set schema = var("dbt_schema") %}
{% set patient_relation_prefix = var("patient_missingness_relation_prefix") %}
{% set assessment_relation_prefix = var("assessment_missingness_relation_prefix") %}
{% set assessment_followup_relation_prefix = var("followup_missingness_relation_prefix") %}
{% set delivery_relation_prefix = var("delivery_missingness_relation_prefix") %}
{% set household_relation_prefix = var("household_missingness_relation_prefix") %}
{% set household_visit_relation_prefix = var("household_visit_missingness_relation_prefix") %}
{% set immunization_relation_prefix = var("immunization_missingness_relation_prefix") %}
{% set postnatal_follow_up_relation_prefix = var("postnatal_follow_up_missingness_relation_prefix") %}
{% set pregnancy_relation_prefix = var("pregnancy_missingness_relation_prefix") %}
{% set pregnancy_follow_up_relation_prefix = var("pregnancy_follow_up_missingness_relation_prefix") %}


{% set patient_column_names = get_column_names(schema=schema, relation_prefix=patient_relation_prefix) %}
{% set patient_column_names = filter_by_list(list_to_filter=patient_column_names, list_of_words=var("patient_missingness_cols")) %}

{% set assessment_column_names = get_column_names(schema=schema, relation_prefix=assessment_relation_prefix) %}
{% set assessment_column_names = filter_by_word(list_to_filter=assessment_column_names, word_to_filter="follow_up") %}
{% set assessment_column_names = filter_by_list(list_to_filter=assessment_column_names, list_of_words=var("assessment_missingness_cols")) %}

{% set assessment_followup_column_names = get_column_names(schema=schema, relation_prefix=assessment_followup_relation_prefix) %}
{% set assessment_followup_column_names = filter_by_list(list_to_filter=assessment_followup_column_names, list_of_words=var("followup_missingness_cols")) %}

{% set delivery_column_names = get_column_names(schema=schema, relation_prefix=delivery_relation_prefix) %}
{% set delivery_column_names = filter_by_list(list_to_filter=delivery_column_names, list_of_words=var("delivery_missingness_cols")) %}

{% set household_column_names = get_column_names(schema=schema, relation_prefix=household_relation_prefix) %}
{% set household_column_names = filter_by_word(list_to_filter=household_column_names, word_to_filter="visit") %}
{% set household_column_names = filter_by_list(list_to_filter=household_column_names, list_of_words=var("household_missingness_cols")) %}

{% set household_visit_column_names = get_column_names(schema=schema, relation_prefix=household_visit_relation_prefix) %}
{% set household_visit_column_names = filter_by_list(list_to_filter=household_visit_column_names, list_of_words=var("household_visit_missingness_cols")) %}

{% set immunization_column_names = get_column_names(schema=schema, relation_prefix=immunization_relation_prefix) %}
{% set immunization_column_names = filter_by_list(list_to_filter=immunization_column_names, list_of_words=var("immunization_missingness_cols")) %}

{% set postnatal_follow_up_column_names = get_column_names(schema=schema, relation_prefix=postnatal_follow_up_relation_prefix) %}
{% set postnatal_follow_up_column_names = filter_by_list(list_to_filter=postnatal_follow_up_column_names, list_of_words=var("postnatal_follow_up_missingness_cols")) %}

{% set pregnancy_column_names = get_column_names(schema=schema, relation_prefix=pregnancy_relation_prefix) %}
{% set pregnancy_column_names = filter_by_word(list_to_filter=pregnancy_column_names, word_to_filter="follow_up") %}
{% set pregnancy_column_names = filter_by_list(list_to_filter=pregnancy_column_names, list_of_words=var("pregnancy_missingness_cols")) %}

{% set pregnancy_follow_up_column_names = get_column_names(schema=schema, relation_prefix=pregnancy_follow_up_relation_prefix) %}
{% set pregnancy_follow_up_column_names = filter_by_list(list_to_filter=pregnancy_follow_up_column_names, list_of_words=var("pregnancy_follow_up_missingness_cols")) %}

with missingness_final as (
    SELECT
    chv.chv_uuid,
    chv.branch_name, 
    {% for patient_column in patient_column_names %}
    {{ patient_column }}_patient_missing,
    {% endfor %}
    {% for delivery_column in delivery_column_names %}
    {{ delivery_column }}_delivery_missing,
    {% endfor %}
    {% for household_column in household_column_names %}
    {{ household_column }}_household_missing,
    {% endfor %}
    {% for household_visit_column in household_visit_column_names %}
    {{ household_visit_column }}_household_visit_missing,
    {% endfor %}
    {% for immunization_column in immunization_column_names %}
    {{ immunization_column }}_immunization_missing,
    {% endfor %}
    {% for postnatal_follow_up_column in postnatal_follow_up_column_names %}
    {{ postnatal_follow_up_column }}_postnatal_follow_up_missing,
    {% endfor %}
    {% for pregnancy_follow_up_column in pregnancy_follow_up_column_names %}
    {{ pregnancy_follow_up_column }}_pregnancy_follow_up_missing,
    {% endfor %}
    {% for pregnancy_column in pregnancy_column_names %}
    {{ pregnancy_column }}_pregnancy_missing,
    {% endfor %}
    {% for assessment_column in assessment_column_names %}
    {{ assessment_column }}_assessment_missing,
    {% endfor %}
    {% for assessment_followup_column in assessment_followup_column_names %}
    {{ assessment_followup_column }}_assessment_followup_missing
    {% if not loop.last %},{% endif %}
    {% endfor %} 
    FROM {{ ref('chv') }} chv
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for patient_column in patient_column_names %}
    SUM({{ patient_column }}_patient_missing) AS {{ patient_column }}_patient_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_patient_missingness') }} pm
    ON pm.chv_area_id = chv.cu_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) patient_missing
    on chv.chv_uuid = patient_missing.chv_uuid and chv.branch_name = patient_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for delivery_column in delivery_column_names %}
    SUM({{ delivery_column }}_delivery_missing) AS {{ delivery_column }}_delivery_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_delivery_missingness') }} dm
    ON dm.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) delivery_missing
    on chv.chv_uuid = delivery_missing.chv_uuid and chv.branch_name = delivery_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for household_column in household_column_names %}
    SUM({{ household_column }}_household_missing) AS {{ household_column }}_household_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_household_missingness') }} hm
    ON hm.chv_area_id = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) household_missing
    on chv.chv_uuid = household_missing.chv_uuid and chv.branch_name = household_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for household_visit_column in household_visit_column_names %}
    SUM({{ household_visit_column }}_household_visit_missing) AS {{ household_visit_column }}_household_visit_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_household_visit_missingness') }} hvm
    ON hvm.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) household_visit_missing
    on chv.chv_uuid = household_visit_missing.chv_uuid and chv.branch_name = household_visit_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for immunization_column in immunization_column_names %}
    SUM({{ immunization_column }}_immunization_missing) AS {{ immunization_column }}_immunization_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_immunization_missingness') }} im
    ON im.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) immunization_missing
    on chv.chv_uuid = immunization_missing.chv_uuid and chv.branch_name =immunization_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for postnatal_follow_up_column in postnatal_follow_up_column_names %}
    SUM({{ postnatal_follow_up_column }}_postnatal_follow_up_missing) AS {{ postnatal_follow_up_column }}_postnatal_follow_up_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_postnatal_follow_up_missingness') }} pnfum
    ON pnfum.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) postnatal_follow_up_missing
    on chv.chv_uuid = postnatal_follow_up_missing.chv_uuid and chv.branch_name =postnatal_follow_up_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for pregnancy_follow_up_column in pregnancy_follow_up_column_names %}
    SUM({{ pregnancy_follow_up_column }}_pregnancy_follow_up_missing) AS {{ pregnancy_follow_up_column }}_pregnancy_follow_up_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_pregnancy_follow_up_missingness') }} pfum
    ON pfum.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) pregnancy_follow_up_missing
    on chv.chv_uuid = pregnancy_follow_up_missing.chv_uuid and chv.branch_name =pregnancy_follow_up_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for pregnancy_column in pregnancy_column_names %}
    SUM({{ pregnancy_column }}_pregnancy_missing) AS {{ pregnancy_column }}_pregnancy_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_pregnancy_missingness') }} pfum
    ON pfum.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) pregnancy_missing
    on chv.chv_uuid = pregnancy_missing.chv_uuid and chv.branch_name = pregnancy_missing.branch_name
    JOIN 
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for assessment_column in assessment_column_names %}
    SUM({{ assessment_column }}_assessment_missing) AS {{ assessment_column }}_assessment_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_assessment_missingness') }} am
    ON am.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) assessment_missing
    on chv.chv_uuid = assessment_missing.chv_uuid and chv.branch_name = assessment_missing.branch_name
    JOIN
    (
    SELECT 
    chv.chv_uuid,
    chv.branch_name, 
    {% for assessment_followup_column in assessment_followup_column_names %}
    SUM({{ assessment_followup_column }}_assessment_followup_missing) AS {{ assessment_followup_column }}_assessment_followup_missing
    {% if not loop.last %},{% endif %}
    {% endfor %}
    FROM {{ ref('chv') }} chv
    LEFT JOIN {{ ref('chv_assessment_follow_up_missingness') }} am
    ON am.reported_by = chv.chv_uuid
    GROUP BY chv.chv_uuid, chv.branch_name
    ) assessment_followup_missing
    on chv.chv_uuid = assessment_followup_missing.chv_uuid and chv.branch_name = assessment_followup_missing.branch_name
)

SELECT * FROM missingness_final