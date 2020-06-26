# Improving Data Quality in Community Health Settings

This repo is for DataKind's CHW Impact Practice Cohort 1: the Medic Mobile Data Integrity Project and is laid out as follows

- __dbt__: dbt project directory for modeling and testing community health data. More details are available [here](https://github.com/datakind/chw1-mm-data-integrity/blob/master/dbt/README.md).
- __docs__: Documentation for "the Community Health Data Quality Cookbook", including setup instructions for the full stack and theoretical examples for writing additional tests for specific types of data quality challenges.
- __experimental__: Miscellaneous code left over from ideas that did not make the core data pipeline but that we've elected to include in case it provides useful inspiration for future tweaks. Includes early scoping and experimentation notebooks that have not been updated since the first stages of the project. Code here is for reference only, and shouldn't be assumed to run automatically.
- __generated_reports__: This directory will be empty when cloned, but reports and imagery created by the data pipelines will be stored here.
- __great_expectations__: Great expectations project directory, more details are available [here](https://github.com/datakind/chw1-mm-data-integrity/blob/master/great_expectations/run_ge.py).
- __notebooks__: All exploratory data analysis performed in support of this project is captured here Jupyter notebooks.

In addition, there are two key scripts to be aware of:

- __run_everything.sh__: This shell script is a single-command to run the entire pipeline, including dbt and great expectations tests and generation of reports and images.
- __generate_test_view_report.py__: This python script is the primary creator of coverage reports and visual artifacts. It should be run from this top-level directory because it relies on inputs from both the dbt and great expectations portions of the pipeline.
