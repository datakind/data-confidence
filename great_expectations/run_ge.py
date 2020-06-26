import datetime
import json
import ast
import traceback

import great_expectations as ge
import pandas as pd
import yaml
import sqlalchemy as sa
import psycopg2
from psycopg2 import sql

from pandas.io.json import json_normalize

with open('batch_config.json', 'r') as opened:
    config = json.load(opened)

# The json file specifies three things:
# 1. The datasource, as configured in great_expectations.yml
# 2. The name of the expectation suite that holds the expectations
# 3. A table you want as an entry point
# Note: Ideally, our expectations will take in a table name as an argument
# and do not rely on the table chosen here. Great Expectations, however, expects a table

with open('great_expectations.yml', 'r') as opened:
    ge_config = yaml.load(opened)
    db_config_path = ge_config['config_variables_file_path']

with open(db_config_path, 'r') as opened: # Assumes the credentials are stored in a local file
    db_config = yaml.load(opened)[config["datasource_name"]]
    
def parse_unexpected_list(unexpected):
    """Converts a pandas Series or a string representation into a list, or pass on the list if it already was one. This is to
    make sure we can read the results from both a file or in-memory directly from Great Expectations."""
    
    if isinstance(unexpected, str):
        values = ast.literal_eval(unexpected)
    elif isinstance(unexpected, list):
        values = unexpected
    elif isinstance(unexpected, pd.Series):
        values = unexpected.to_list()
    else:
        values = []
    return values

def create_views(results):
    connection = psycopg2.connect(host=db_config["host"], user=db_config["username"], password=db_config["password"],
                    dbname=db_config["database"])

    cursor = connection.cursor()

    for i, result in results.iterrows():
        try:
            if result['error']:
                print(f"Failed to execute {result['expectation_config.expectation_type']}")
                continue
            elif result['fail']:
                source_table = result['result.table']
                source_column = result['result.id_column']
                if result['result.short_name'].startswith('chv_'):
                    name = f"chv_tr_{result['result.short_name'][4:]}" # Moves the chv_ substring ahead
                else:
                    name = f"tr_{result['result.short_name']}"

                raw_values = result['result.unexpected_list']
                values = parse_unexpected_list(raw_values)

                #Weird super slowdown if using "create or replace view" as opposing to dropping view first 
                query_drop = sql.SQL('drop view if exists {name}').format(name=sql.Identifier(name))
                cursor.execute(query_drop)
                connection.commit()

                query_create = sql.SQL('create view {name} as select * from {source_table} inner join unnest(%s) as failed on failed={source_table}.{source_column}').format(name=sql.Identifier(name), source_table=sql.Identifier(source_table), source_column=sql.Identifier(source_column))
                cursor.execute(query_create, (values,))
                connection.commit()
                print(f'Created view at {name} with {len(values)} rows')
        except:
            traceback.print_exc()
            continue
    
    connection.close()

def parse_results(results):
    """Assumes a dictionary where there is only one key at the top level.
    The goal here is to produce a dataframe readable by the test coverage"""

    for key in results['details']:
        actual_results = results['details'][key]['validation_result']['results']

    results = [result.to_json_dict() for result in actual_results] #

    results = json_normalize(results)
    
    results['fail'] = ~results['success']
    results['error'] = results['exception_info.raised_exception']
    results['status'] = results['result.unexpected_list'].apply(lambda x: len(parse_unexpected_list(x)))
    results['warn'] = False # because we don't have that concept yet
    results['skip'] = False # we also don't ever skip expectations yet

    results.to_csv('ge_clean_results.csv', index=False)
    return results

def main():
    """Uses configuration to create a validation batch and runs an expectation suite on it"""

    context = ge.data_context.DataContext()
    batch_kwargs = {"table": config['table'], "datasource": config['datasource_name']}
    batch = context.get_batch(batch_kwargs, config['expectation_suite_name'])

    results = context.run_validation_operator(
        "action_list_operator",
        assets_to_validate = [batch])

    results = parse_results(results)

    create_views(results)

    return results

if __name__ == '__main__':
    main()
