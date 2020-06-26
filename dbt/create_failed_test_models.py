import json
import argparse
import os
import re


parser = argparse.ArgumentParser()
parser.add_argument("--tables", action='store_true',  help="Create files that yield tables instead of views")
args = parser.parse_args()

output_type = 'view'
if args.tables:
    output_type = 'table'

# Purge old tests
for i in os.listdir('models/test/'):
    if i.endswith('sql'):
        os.remove('models/test/'+i)

# Note that this uses the archived results so that 
# it can be rerun independent of the most recently run 
# test suite. It will only pick up changes when run_results.json
# is archived, either manually or via run_everything.sh

with open('target/run_results_archive.json') as f:
    run_results = json.load(f)
    
for i in run_results['results']:
    # Only create models for tests that have failed
    if i['status'] != 0:
        
        try:
            model_name = i['node']['test_metadata']['kwargs']['name']
        except (TypeError, KeyError):
            model_name = i['node']['name']

        query = i['node']['compiled_sql']
        
        # Modify queries to return full rows instead of counts
        query = re.sub(r'select\s+count\(\*\)\s+','select * ', query)

        # Find/replace absolute table references with models
        # to preserve DBT's DAG awareness
        for model_label in re.findall(r'\s"\w+"\."\w+"\."\w+"', query):
            new_label = model_label.split(".")[-1].replace('"','')
            query = query.replace(model_label, " {{ ref('"+new_label+"') }}")
        
        with open(f'models/test/tr_{model_name}.sql', 'w') as f:
            f.write("{{{{ config(materialized='{0}') }}}} \n\n".format(output_type) + query)