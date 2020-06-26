#!/bin/bash

##### DBT #####

# Reload raw data in DBT and run tests
echo "running dbt tests"
cd dbt
dbt run -m core
dbt test -m core

# Generate DBT test coverage reports
python generate_test_coverage_report.py > test_coverage.txt

echo "creating views for failing dbt tests"
# Create views for failing DBT tests
cp ./target/run_results.json ./target/run_results_archive.json
python create_failed_test_models.py
dbt run -m test
cp ./target/run_results.json ./target/run_results_test.json

dbt run -m chv_level_iop
cp ./target/run_results.json ./target/run_results_chv_level.json

# Cleanup
cd ..
cp ./dbt/test_coverage.txt ./generated_reports/dbt_test_coverage.csv

##### GREAT EXPECTATIONS #####

# Run Great Expectations tests and create views
echo "running great expectations tests and creating views"
cd great_expectations
python run_ge.py

# Cleanup
cd ..
cp ./great_expectations/ge_clean_results.csv ./generated_reports/ge_clean_results.csv


##### OVERALL REPORTING #####

# Generate overall coverage reports
echo "building reports and visuals"
python generate_test_view_report.py > generated_reports/test_view_report.txt
echo "done"