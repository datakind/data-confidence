# Validating Community Health Data with Great Expectations

## What's in here

This directory is a [Great Expectations](https://greatexpectations.io/) project.

- Core directories
  - __expectations:__ JSON files indicating the tests to be run (similar to yml files containing schema tests in DBT)
  - __notebooks:__ Jupyter notebooks automatically created by Great Expectations during setup to allow for a more convenient front-end to edit the JSON files in `expectations` (check out the flow described by the [Great Expectations documentation](https://docs.greatexpectations.io/en/latest/how_to_guides/creating_and_editing_expectations/how_to_edit_an_expectation_suite_using_a_disposable_notebook.html))
  - __plugins:__ Additional code for customizing this Great Expectations project. Most important in here is `custom_expectations.py`, which is where tests requiring arbitrary python should be added as methods under the `CustomSqlAlchemyDataset` class (somewhat similar to the custom SQL tests in DBT, except written in python).

- Non-version controlled directories (automatically created by other processes)
  - __uncommitted:__ Generic place to capture all Great Expecations files that should not be version controlled, including logs and database connection details

- Scripts
  - __run_ge.py:__ Wrapper script to automatically run GE tests and create coverage reports. GE's CLI commands for this are much more verbose and more difficult to remember than DBTs, so we found it useful to wrap these in a script.

- Config files
  - __batch_config.json:__ Defines datasources, test suites, and tables to be included when running Great Expectations
  - __great_expectations.yml:__ Main config file for Great Expectations (similar to `dbt_project.yml`)

## Installation and setup

The instructions below will set up the Great Expectations side of the stack on its own. To set up the full stack, including Great Expectations, follow the [Getting Started Guide](../docs/getting_started.md)

A warning about its installation on a Windows machine: filepaths might exceed the native limit and an administrator might need to change the limit for the framework to be installed and work correctly.

1. Install dependencies with the file requirements.txt (above this directory level) with either pip or conda, such as: `pip install -r requirements.txt`

2. Create a file `uncommitted/config_variables.yml` and add the required information to allow the framework to connect to the database. Refer to `sample_config_variables.yml` as an example.

This is not a required step in the configuration process, but for context, the file `great_expectations.yml` informs Great Expectations in terms of where custom expectations and database credentials are located, where results can be stored, etc. The default file in this repository is usable as is.

## Terminology

- An expectation is a particular function accepting one or multiple parameters (defined in Python)
- A test is an instance of an expectation, with a specific set of parameters (defined in a JSON file)
- Out of the box (OOTB) expectations are provided by Great Expectations and built-in with the library's codebase.

## Structuring tests

- Tests are defined in JSON, akin to dbt schema tests in yaml
  - These live in a suite called `great_expectations/expectations/<FILE>.json`

- Tests can be used OOTB, or written custom
  - Custom expectations can operate on any tables passed as a parameter, but OOTB expectations will only be applied on the selected table in batch_config.json (see extra notes below for details)
  - OOTB tests can use views defined in DBT
  - OOTB tests can be defined directly in the JSON file
  - Custom expectations need to be added as decorated methods in plugins/custom_expectations.py
    - Custom tests can run arbitrary python/pandas (even though this isn't well-documented in the GE published docs)
      - Once added to in custom_expectations.py, tests can be defined in the JSON file similarly to OOTB tests
    - OOTB tests have a variety of outputs and therefore might not conform to the format expected by the Data Integrity framework.

## Custom documentation

If a mix of OOTB and custom expectations are needed, it is suggested to keep them in two suites of tests to manage their differences efficiently

## Running tests

From the command line
`python run_ge.py`

Great Expectations has some command-line tools but they are in flux at the moment, so it's preferable to use run_ge. If you still want to run a suite interactively, you can do:

`great_expectations validation-operator run --name action_list_operator --suite <name_as_found_under_expectations_directory>`

This tool will ask you to choose a table or define a SQL query, which is the same as the `table` field in `batch_config.json`

## Extra notes

The data integrity tool works with a few assumptions in terms of what an expectation should accept and return.

1. We create views out of the IoP results with Postgresql-specific syntax. If you're using any other database engine, please adapt the query in run_ge.py.

2. An expectation accepts both column names and table names as arguments. Great Expectations generally has table-agnostic suites running on specific single tables, but we're changing this model a bit because data integrity queries often depend on more than one table. Therefore, a default table is set in a batch_config.json for all custom expectations, and we suggest that a relevant table name is passed to the expectation in the suite definition. The default table won't be read at all and is used as a placeholder.

3. Custom expectations are found in custom_expectations.py under plugins, it is recommended to follow their format and to add your own custom expectations as methods of that same class.

4. The tool's post-processing step expects a few specific field in the output of the expectations (refer to example custom expectations to see how they're implemented, and the cookbook for a detailed overview)
