# Getting Started

## Assumptions and Requirements

To use these tools, the following should be true:

- You have Python 3.7+ installed
- Your data is stored in a postgres database. Portions of this setup could be used with other types of relational databases, but postgres (or equivalents) are required to make use of the full stack
- You have common community health data concepts (e.g. assessments, patients, supervisors, pregancies, etc.) stored each as separate tables in your database

## Initial Installation

Before running any tests with DBT or Great Expectations, ensure your environment is setup with the right packages. A [python virtual environment](https://docs.python.org/3/library/venv.html) should be used to ensure your environment is clean and not interfering with other packages / environments on your computer that could cause conflicts.

- Setup a python virtual environment

```bash
python3 -m venv venv
```

- Activate the virtual environment

```bash
source venv/bin/activate
```

- Install the packages in requirements.txt

```bash
pip install -r requirements.txt
```

## Configuring DBT

- Create a profiles.yml file in the ```~/.dbt``` directory

This is what specifies which database to connect to when running `dbt` commands. # You can create the file with the following shell commands:

```bash
mkdir ~/.dbt
vi ~/.dbt/profiles.yml
```

Edit the file based on the template below, replacing values where indicated.

```yaml
default:
  target: dev
  outputs:
    dev:
      type: postgres
      host: <your_host_ip>
      user: <your_database_username>
      pass: <your_password>
      port: 5432 # This is the default postgres port
      dbname: <your_database_name>
      schema: <schema_where_your_modeled_data_should_go>
      threads: 4
    # You can configure DBT for multiple environments (e.g. dev vs prod)
    # We have only used one (dev) in developing this stack, but your mileage may vary
    other_env_here:
      type: postgres
      host: <your_other_host_ip>
      user: <your_other_database_username>
      pass: <your_other_password>
      port: 5432
      dbname: <your_other_database_name>
      schema: <other_schema_where_your_modeled_data_should_go>
      threads: 4
```

- Install DBT dependencies

```bash
cd dbt
dbt deps
```

## Configuring Great Expectations

- Create a file `great_expectations/uncommitted/config_variables.yml` and add the required information to allow the framework to connect to the database. Refer to sample_config_variables.yml as an example, where the format is:

```yaml
<datasource_name>:
    drivername: postgres
    host: localhost
    port: '5432'
    username: myusername
    password: "mypassword"
    database: postgres
```

- Adjust any variable in `great_expectations/great_expectations.yml`. This is not a required step in the configuration process, but for context, the file informs Great Expectations in terms of where custom expectations and credentials are located, where results can be stored, etc. The default file in this repository is usable as is.

## Run everything

Assuming that your tables have the same names indicated in `/dbt/models/core`, at this point you should be able to run `run_everything.sh` from the top of the directory. This will run both DBT and Great Expectations test suites, creates the appropriate views, and generate the coverage reports that can will populate in `generated_reports`.

## Writing your first tests

Once you've confirmed that your database connections are working and you're able to run the stack as written, you'll probably want to start writing new tests of your own. For more details on how to do this, check out the [DBT](./dbt.md) or [Great Expectations](./great_expectations.md) specific documentation. Of the many options availble, the simplest way to get add new tests quickly is to start with [schema tests in DBT](./dbt.md#schema_tests).
