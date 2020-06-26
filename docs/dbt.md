# Testing in dbt  

## DBT basics

DBT is traditionally used to support the transformations in a "Extract, Load, Transform" (ELT) data pipeline with a powerful set of modelling tools on which tests can be run after the fact. In this case, we spend much more focus on the test suite and less focus on the models creation.

DBT contains a variety of useful command line options for [updating models, running tests, and more](https://docs.getdbt.com/docs/running-a-dbt-project/command-line-interface/). Some of the more commonly used commands in the project include:

- `dbt run`: DBT connects to the target database and runs the relevant SQL required to materialize all data models using the specified materialization strategies
- `dbt test`: Runs tests on data in deployed models. This can be ran with the `-m` option to specify which set of models to run tests for (ex: `dbt test -m core`). Additionally, you can specify the `--schema` or `--data` option to run either schema or data tests (ex: `dbt test --schema`)

## Schema Tests

Schema tests are tests defined in YAML files and are intended to be as quick to implement as possible. There are many kinds of schema tests, ranging from those that come included with DBT all the way to fully-custom macro-based tests.

### Built-in tests

DBT contains built-in schema tests for a variety of common IOP issues, including checking for missing data, unexpected values, and foreign key integrity. The DBT docs [describe the complete list of built-in schema tests](https://docs.getdbt.com/docs/building-a-dbt-project/testing-and-documentation/testing/#built-in-tests) in detail. These tests can be invoked simply by adding them to any YAML file in the `models` directory. For example, tests to check that the UUID column on a table containing a list of households is both always populated and unique can be created using the following YAML snippet

```yml
models:
    - name: household
      columns:
          - name: uuid
            tests:
                - unique
                - not_null
```

### dbt-utils

In addition to the built-in schema tests, dbt also allows plugins that support additional functionality. [DBT-utils](https://github.com/fishtown-analytics/dbt-utils) is one of the most popular of these plugins, and it's useful here because it includes additional built-in schema tests to supplement those appearing in core DBT. DBT-utils is already configured with this project (installation is configured in `dbt/packages.yml`)

While DBT-utils allows many additional types of extra schema tests, one of the most useful for this work is the [expression_is_true](https://github.com/fishtown-analytics/dbt-utils#expression_is_true-source) test, which enables easy testing of consistent logic across multiple fields. For example, this YAML snippet implements a test to find any situations where the `malnutrition_ref` field is in conflict with the `muac_strap_color` fields in a table of assessments

```yml
models:
    - name: assessment
      tests:
        - dbt_utils.expression_is_true:
            name: "malnutrition_ref_negative"
            expression: "not(muac_strap_color in ('red','yellow'))"
            condition: "malnutrition_ref = 'no'"
```

### Custom schema tests using Jinja macros

Schema tests are great for checking for common types of IOP that can appear in multiple places in a database (for example, looking for missing data in multiple columns across multiple tables). It's possible that your dataset might have situations like this for which a schema test would make sense, but that isn't supported by any of the schema test types in either the core DBT code or any plugins. In these situations, custom schema tests can be written as Jinja macros that can then be invoked using the same YAML approach as any other schema test. We won't repeat all the [detailed instructions for how to do this](https://docs.getdbt.com/docs/writing-code-in-dbt/extending-dbts-programming-environment/custom-schema-tests/) here, but as a quick reference example, here's a macro to detect possible duplicate records:

```jinja
{% macro test_possible_duplicate_forms(model) %}

with records_per_patient_hour as (
select
    date_trunc('hour', reported::timestamp) as date_hour,
    patient_uuid,
    count(uuid) as number_of_records
FROM {{ model }}
group by 1, 2
),

possible_duplicate_combinations as (
select *
from records_per_patient_hour
where number_of_records > 1
)

select count(*)
from possible_duplicate_combinations pdc
left join {{ model }} m
on date_trunc('hour', m.reported::timestamp) = pdc.date_hour
and m.patient_uuid = pdc.patient_uuid

{% endmacro %}
```

This test can then be invoked via YAML, like this:

```yml
models:
    - name: assessment
      description: "Raw output of assessment"
      tests:
        - possible_duplicate_forms
```

A few things to keep in mind when writing these kind of tests:

- Custom schema test macros should be saved in the `macros` directory and prefixed with `test_` to indicate that they're tests (and not just otherwise useful macros)
- They should contain SQL code that returns results (or a count>0) in the event of a failed test. Like elsewhere in DBT, passing tests return zero results.
- Custom schema tests may be written at the model level (like the example above) or at the column level. Column-level tests will be invoked under the appropriate column in the YAML file and can reference the `{{column}}` in the underlying SQL.

### Metadata for schema tests

To ensure that test results can be easily organized and turned into downstream models, establishing a baseline level of standard metadata is helpful. Metadata should include a `name`, which *must be less than 64 characters long*. Otherwise, dbt will automatically create very verbose default names which will cause poor performance with downstream exploration of failing test results and IoP dashboards.

## SQL tests

For more complex situations that don't lend themselves well to the simplicity of schema tests, [DBT also supports tests in the form of arbitrary SQL queries](https://docs.getdbt.com/docs/building-a-dbt-project/testing-and-documentation/testing#custom-data-tests). Any expression that can be written as a SQL query can be invoked as a test using this approach. Queries should be structured such that the test passes when no results are returned. Any test query that yields results will be considered as failing.

There are many situations where a test could be written as either a SQL test or a schema test. As a general rule of thumb, if the test is simpler and can be used in multiple places, consider implemeting it as a schema test. If it's more complicated or specific to a particular aspect of the dataset, a SQL test might be better.

### Basic examples

To create a SQL test, save your query in the `dbt/tests` directory. While the filenames don't indicate which tests will be run (as distinct from custom schema tests, which must be prefixed with `test_`), we recommend taking the time to name your SQL tests thoughtfully to help keep your project organized and your test coverage reports easy to understand. It's also important to structure your SQL to reference dbt models (like `{{ ref('household') }}`) instead of a hardcoded table name. This will enable better flexibility in the event that upstream models change and will make it easier to keep track of which tests apply to which data sourfces.

Here's an example of using a custom SQL test to identify communities that have extreme numbers of households.

```jinja
with households_per_community_counts as (

select
  chv_area_id community_id,
  count(*) total_households
from
  {{ ref('household') }}
group by
  chv_area_id

),

statistics as (

select
  (avg(total_households) - (10 * stddev(total_households))) minimum,
  (avg(total_households) + (10 * stddev(total_households))) maximum
from
  households_per_community_counts

)


select
  *
from
  households_per_community_counts
where
  total_households <= (select minimum from statistics)
  or total_households >= (select maximum from statistics)
```

### Using Jinja to make life easier

In some situations where a SQL test might contain repetitive code that might violate [the "Don't Repeat Yourself (DRY) principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself), taking advantage of some of the Jinja templating engine (which is a key dependency of DBT) can streamline your tests substantially. The DBT docs have [several great examples](https://docs.getdbt.com/docs/writing-code-in-dbt/getting-started-with-jinja
) of this.
