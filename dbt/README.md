# Validating Community Health Data with DBT

## What's in here

This directory is a [DBT](https://docs.getdbt.com/docs/introduction/) project containing DBT models, macros, scripts, custom tests, and project files.

- Core directories
  - __macros:__ Jinja macros to support organized code and custom schema tests
  - __models:__ This is the core of the project, containing both SQL for models and yml files for schema tests
  - __tests:__ Custom SQL tests

- Non-version controlled directories (automatically created by other processes)
  - __target:__ Compiled sql used to create models and tests
  - __dbt_modules:__ DBT plugins (e.g. dbt_utils)
  - __logs:__ Logs created by dbt (not used elsewhere in this stack)

- Scripts
  - __create_failed_test_models.py:__ Creates views containing rows with IoP flagged by failing tests
  - __generate_test_coverage_report.py:__ Creates a test coverage report of the DBT side of the stack

- Config files
  - __dbt_project.yml:__ Defines paths to important DBT projects (including those listed above) and project-specific variables
  - __packages.yml:__ Indicates dbt plugins used

## Running tests

- Run all tests: `dbt test -m core`  
- Run all tests for patients only: `dbt test -m patient`  
- Run schema tests for patients only `dbt test --schema -m patient`  
- Run data tests for patients only `dbt test --data -m patient`  

## Updating models

Right now, the models in the `core` folder are just full table copies of the raw data. The models within the `chv_level_iop` folder aggregate the errorneous rows produced by `create_failed_test_models.py` at the CHV level. We expect you'll likely want to update each of these separately (see `run_everything.sh` for how this works in context):

- Update all models: `dbt run -m core`
- Update chv-level aggregated models: `dbt run -m chv_level_iop`

## Writing new tests

Since we'll have lots of tests we want to run, it's important to keep them organized. Wherever possible, schema tests should be implemented in `schema.yml` because it minimizes the need for adding lots of additional SQL. You may find the (already set up on this project) [`dbt_utils` extension](https://github.com/fishtown-analytics/dbt-utils) useful for writing more complex versions of these kinds of tests.

For tests requiring custom SQL, a new SQL file should be created in `tests/core`. We have organized the tests in this folder based on common IoP themes, but this file structure is purely to keep things organized for the user and does not affect DBT.

The names of each SQL file should contain the names of the tables involved in the test and should be as verbose as it needs to be to allow readers to understand what the test does (e.g. "households_with_community_id_not_in_chv_table"). It's probably better to err on the side of overly descriptive here as we use these titles to power automatic documentation.

For more details on implementing tests in dbt please refer to the [dbt section](../docs/dbt.md) in the Community Health IOP cookbook.

## Making sense of failed test results

First, run `dbt test` to make sure that the most recent tests have been run. Then, run `python create_failed_test_models.py` to autogenerate model code for only the tests that have failed. By default, these models will produce views when run, but running the script with the `--tables` argument will instead produce models that generate fully materialized tables. Either way, do a `dbt run` to run the newly created models. The end results will be a new set of data sources (prefixed with "tr_") containing all the rows violating a test.

Because this process can get thrown out of whack easily when you're iterating rapidly, you can run `run_everything.sh` as a quick way to run the right dbt commands in sequence and guarantee that the right dependencies/assumptions are in place to make thing work.

Note that the code generated for these models is gitignored because they're based on compiled SQL and contain specific database names instead of dbt references.

It should also be noted that DBT does support auto-generated documentation out of the box. HOWEVER, these docs are fairly limited in their usefulness for this project, especially since they don't provide a way to find the specific records that are causing a test to fail. This is why we have written new code to generate report that better address the community health IOP use case.

In the event that you do want to explore the native DBT docs, they can be created via `dbt docs generate`. To view them, running `dbt docs serve` will fire up a local web server so you can explore them in a browser.

## Boilerplate Resources

These were listed automatically by `dbt init` and are helpful general resources for learning more about DBT

- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction/)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
