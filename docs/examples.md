# Example tests for different kinds of IoP

## Missingness

Basic tests for missing data are easy to implement using DBT's built-in tests. For example, checking if a specific field has data in it:

__Test:__ A patient should have a date of birth

```yml
- name: patient
  columns:
      - name: date_of_birth
        tests:
          - not_null
```

Sometimes, whether missingness matters might depend on whether other fields have data. We provide a macro for this.

__Test:__ If the animal_bite column has data, animal_bite_duration and animal_bite_alert should also have data.  
__Notebook:__ CHV level missingness: LT-Step-04-CHV-Level-Findings.ipynb

```yml
- name: assessment
  columns:
    - name: animal_bite
      tests:
        - associated_columns_not_null:
            name: animal_bite_details_not_missing
            col_value: "'yes'"
            associated_columns: ["animal_bite_duration", "animal_bite_alert"]
```

## Foreign Key Integrity

Another manifestation of missing data deals with records in one table do not align with records in another table as expected. These can be tested with DBT's `relationships` test.

__Test:__ An assessment should have a corresponding patient and CHV record.

```yml
- name: assessment
  columns:
    - name: patient_uuid
      tests:
        - relationships:
            name: assessments_with_no_patient
            to: ref('patient')
            field: uuid

    - name: reported_by_parent
      tests:
        - relationships:
            name: assessments_with_no_chv
            to: ref('chv')
            field: cu_uuid
```

## Nonsensical values

A common type of IOP is data that makes little practical sense. These types of IOP are usually straightforward to test using built-n DBT tests, like `no_impossible_values`, which allows quick checking for a list of disallowed values

__Test:__ The date of birth listed on an assessment cannot be zero

```yml
- name: assessment
  columns:
    - name: date_of_birth
      tests:
          - no_impossible_values:
              name: assessment_dob_is_not_zero
              values: "('0')"
```

Similar tests can be written for datetime columns. Below is a custom schema test macro, `test_valid_date` and takes in a parameter called earliest_date.

__Test:__ The date of birth listed for a patient should be after a certain threshold.  
__Notebook:__ LT-Step-03-IoP-Findings.ipynb (Patient Data - Section 1)

```yml
    - name: patient
      columns:
          - name: date_of_birth
            tests:
              - valid_date: {"earliest_date": "1885-01-01"}
```

We encountered many columns that stored numeric data as a string, so we created a custom `not_negative_string_column` macro to allow for easy testing of this same type of comparison in across datatypes.

__Test:__ The c_patient_age column, which stores age as a string on the assessment, must be postive.  
__Notebook:__ LT-Step-03-IoP-Findings.ipynb (Followup Data - Section 2)

```yml
- name: assessment
  columns:
      - name: c_patient_age
      tests:
          - not_negative_string_column:
              name: c_patient_age_is_positive
```

The dbt_utils `expression_is_true` test can also be convenient for spotting nonsensical values by writing a simple SQL expression that must always be true for the test to pass.

__Test:__ The weight recorded for a pregnant woman must be greater than zero.

```yml
# This test runs at the table level
- name: pregnancy
  tests:
    - dbt_utils.expression_is_true:
        name: "pregnancy_weight_must_be_positive"
        expression: "weight > 0"
```

Dealing with nonsensical data can be streamlined by applying simple cleaning and consolidation of datatypes and values during model creation. For example, the `fast_breathing` column in the assessments table uses both `true` and `yes` to indicate that patient has fast breathing. It's much easier to write tests that just have to deal with one of these values, so a `fast_breathing_cleaned` column can be easily created during the modeling

```sql


{{ config(materialized='table') }}

WITH source_data AS (

    SELECT *,
    (CASE WHEN fast_breathing IN ('true','yes') THEN 'yes' ELSE 'no' END) AS fast_breathing_cleaned
    FROM assessment

)

SELECT *
FROM source_data
```

## Inconsistent internal logic between fields

A table may contain fields that should always be logically aligned, and it's important to be able to detect when they aren't. There are many ways to write tests for this depending on the complexity of the logic being checked.

The simplest uses dbt_utils' `expression_is_true` test, which will test whether any valid SQL logical expression evaluates to True. Depending on the details of the logic being tested, it might make sense to contain the entire logical expression in one line (like [the example in DBT's docs](https://github.com/fishtown-analytics/dbt-utils#expression_is_true-source)) or combine the expression with an additional `condition` such that it will only be evaluated on certain rows, as shown below.

__Test:__ If an assessment indicates both a fever and jaundice, the jaundice_alert should be 'yes'

```yml
# This test is defined at the table level
- name: assessment
  tests:
    - dbt_utils.expression_is_true:
        name: "jaundice_alert_negative"
        expression: "not(fever = 'yes' and jaundice = 'yes')"
        condition: "jaundice_alert = 'no'"
```

If the logic being tested is particularly complex and can't be defined easily in a straightforward SQL expression, these tests can also be written in Great Expectations, which support arbitrary logic in Pandas. We recommend only doing this when writing the test in SQL would be unnecessarily cumbersome.

TODO: GE Example

## Data that conflicts with CHW protocols

Similar to IOP where a data point is in logical conflict with itself are situations where a data point conflicts with common protocols used by CHWs.

These might appear like missing data and use the same types of test patterns, for example.

__Test__: If a patient received intermittent preventative therapy for malaria, then a dose should be recorded

```yml
- name: pregnancy_follow_up
  columns:
  - name: malaria_ipt
    tests:
      - associated_columns_not_null:
          col_value: "'yes'"
          associated_columns: ["malaria_ipt_dose"]
```

They could also more closely resemble the logical consistency test and use those paradigms.

__Test__: If an assessment is of a patient that meets specific diagnostic and demographic criteria, they should be listed as needing treatment.

```yml
- name: assessment
  columns:
  - dbt_utils.expression_is_true:
      name: "needs_treatment_negative"
      expression: "not(r_has_danger_sign = 'no' and patient_age_in_months >=2 and patient_age_in_years <= 5 and (cough = 'yes' or mrdt_result = 'positive' or has_diarrhoea = 'yes'))"
      condition: "needs_treatment = 'no'"
```

__Test:__ Patients potentially given OPV 1, 2, or 3 vaccines too early to prevent Polio according to health guidelines.

Recommended timeframe for OPV vaccines:

* OPV 1 --> 6 weeks +/- 1 week
* OPV 2 --> 10 weeks +/- 1 week
* OPV 3 --> 14 weeks +/- 1 week

This test assesses if the vaccine was given too early, allowing for the 1 week buffer time. This was done by taking the appointment date in immunization_details and finding the number of days between the appointment date and the patient's DOB. This test was created in great_expectations and outputs the list of patient ids that potentially received the immunization too early as the success criteria. 

```return {
        "success": len(unexp) == 0,
        "result": {"unexpected_list": unexp,
                   "table": form_name,
                   "id_column": patient_key,
                   "short_name": f"OPV123_given_too_early_in_{form_name}"}}
```



## Inconsistent cross-table relationships

There may be cross table relationships where the logic in one column does not match what is expected in another column from a different table. There are many ways to write tests for this but the most straight-forward approach we have found was by writing SQL tests.

__Test:__ If a patient has multiple households assigned to them then this SQL query will yield >0 rows.

```yml
-- patients that have multiple households assigned to them.
with source_data as (
    select
      h.uuid household_id,
      p.uuid patient_id
    from
      {{ ref('household') }} h
      full outer join {{ ref('patient') }} p on p.parent_uuid = h.uuid
)

select
  patient_id,
  count(*)
from
  source_data
where
  patient_id is not null
  and household_id is not null
group by
  patient_id
having
  count(*) > 1
```

## Connections between conditions, symptoms, and treatments

Another variation of this type of test focuses on the combinations of different types of events. During our exploratory data analysis, we identfied instances where symptoms where spotted for a condition, but the treatments given may not have matched what was expected. These dependencies will vary substantially between specific pathologies and patient populations, which makes testing them with out of the box schema test or generalized macro-based tests difficult. Instead, these are excellent candidates for custom SQL testing.

__Test:__ Malaria symptoms should correspond to appropriate treatment and follow up

Rather than duplicate lengthy SQL here, please see `tests/outlier_detection/malaria_testing_and_treatment.sql` for the full details of this example

## Duplicated data

Like missing data, duplicate data takes many forms. The most straightforward duplication to test for is uniqueness within a certain column, which can be checked easily with the native dbt `unique` schema test.

__Test:__ Patient UUIDs must be unique

```yml
- name: patient
  columns:
      - name: uuid
        tests:
            - unique
```

TODO: Example of uniqueness test across multiple columns

In other situations, determining whether an entry is a duplicate can be more complex, and might not be able to be easily tested. In these situations, it might make sense to use a test to flag possible duplicate records for further review.

For these situations, we've developed a custom schema test that flags situations where rows are created for the same patient in the same table within one hour. Alternate time intervals can be implemented by modifying or making new versions of `test_possible_duplicate_forms.sql`

__Test:__ Patients shouldn't have more than one assessment within one hour
__Notebook__: notebooks/NS-5.0-Date Inconsistencies.ipynb

```yml
# This test runs at the table level
- name: assessment
  tests:
    - possible_duplicate_forms
```

To distinguish these tentative IOP cases from known IOP cases, it might make sense to use the `warn` severity level so that failures on these tests can be kept separate until they're confirmed to be actual duplicates.

For other types of potential duplicate data points that can't be detected based on generalized logic, custom SQL tests can be written to capture more bespoke scenarios. For example, our EDA found groups of assessment follow-ups occuring within a few minutes of each other. Therefore, we created a custom test to flag follow-ups occuring within 30 minutes of a previous follow-up (this test does not include the difference in time between the assessment and the follow-up though).

Just like YAML-based schema tests, custom SQL tests are considered failing when they return nonzero results. SQL tests may also fit well with customized upstream models, like `assessment_followup_timing.sql` used here.

__Test:__ Multiple follow-ups should not occur within 30 minutes of one another

```sql
WITH followups_lessthan30min AS (
SELECT a.*,
    (CASE WHEN a.datediff_followup_min <= 30 THEN 1 ELSE 0 END) AS followup_timing_warning
FROM {{ ref('assessment_followup_timing') }} a

)

SELECT *
FROM followups_lessthan30min
WHERE followup_timing_warning = 1
```

## Technically possible, but unlikely values (statistical outliers)
Statistical methods like bootstrapping allow us to detect if Community Health Workers are measuring quantities like temperature in a way that's biased. This might lead to questions such as "Is their device badly calibrated?" or "Are they measuring this quantity in different situations?"

Here's one way to do bootstrapping, taken from this [file](../great_expectations/plugins/custom_expectations.py):
```python
def get_bs_p_scores(table, col, grouping_key, N_samp):
    group = table.dropna(subset=[col]).groupby(grouping_key)[col].agg(['mean','std','count'])
    bs = np.random.choice(table[col].dropna(), size = (group.shape[0],N_samp))

    def bootstrap_p(g):
        return (g['mean'] < bs[:int(g['count']),:].mean(axis=0)).mean()

    group['bs_p_score'] = group.apply(bootstrap_p,axis=1)
    return group
```
__Notebook__: [notebooks/NS-8.0-Bootstrap-Anomaly-Test.ipynb](../notebooks/NS-8.0-Bootstrap-Anomaly-Test.ipynb)

## Unpacking JSON for tests
__Test:__ Patients potentially given OPV 1, 2, or 3 immunizations too early, however the data from the visit is wrapped in JSON.
__Notebook__: notebooks/MT - Immunization Exploration 

This function is built in to the immunization_opv_given_too_early expectation, however, can easily be repurposed if there are other columns filled with JSON that needs to be unpacked. The package used was rapidjson as it was found to have the most time efficiency. 
```
        df_sub = df[[key,unpack_key]]

        i = 0
        count = 0
        all_temps = []
        while i < len(df_sub):
            if df_sub[unpack_key][i] != None:
                try:
                    df_temp = rapidjson.loads(df_sub[unpack_key][i])
                    uuid = df_sub[key][i]
                    if isinstance(df_temp, list):
                        for d in df_temp:
                            d[key] = uuid
                            all_temps.append(d)
                    else:
                        df_temp[key] = uuid
                        all_temps.append(df_temp)
                except:
                    count +=1
            i+=1
        df = pd.DataFrame(all_temps)
```
In order to not lose the row identity, the key (uuid) was used to merge the unpacked json, back to the source table. The unpack_key in this case is the column that is filled with json that requires flattening before being utilized in furthers tests/expectations.
