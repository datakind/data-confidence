#%%
import json
from itertools import chain, cycle

import numpy as np
import pandas as pd
# from pandas import json_normalize
from pandas.io.json import json_normalize

import matplotlib.pyplot as plt

import seaborn as sns
sns.set_context('notebook')

import sys
import os
# %%
## Connect to Postgres database with data and DBT error views
import psycopg2 as pg
import yaml
from pathlib import Path

with open(Path.home() / ".dbt/profiles.yml") as f:
    db_config = yaml.load(f,Loader=yaml.FullLoader)


db_credentials = db_config['default']['outputs']['dev']
conn = pg.connect(host=db_credentials['host'], user=db_credentials['user'],
                password=db_credentials['pass'], port=db_credentials['port'], 
                dbname=db_credentials['dbname'] )

# %%

## Load and parse DBT error results
with open('dbt/target/run_results_test.json') as f:
    run_results = json.load(f)
    
dbt_results = json_normalize(run_results['results'])

# Get rid of verbose columns we don't need
dbt_results.drop(list(dbt_results.filter(regex = '_sql')), axis = 1, inplace = True)
dbt_results.drop(list(dbt_results.filter(regex = '_path')), axis = 1, inplace = True)

dbt_results.rename(columns={'node.alias': 'test_name'}, inplace=True)

# Unravel nested list of refs and add tag columns
dbt_results['referenced_tables'] = dbt_results['node.refs'].apply(chain.from_iterable).apply(list)

# Separate out the tests that have successfully created views from those that failed
errors = dbt_results[dbt_results['status']=='ERROR'][['test_name','error']]
successes = dbt_results[dbt_results['status']=='CREATE VIEW'][['test_name', 'referenced_tables']]



# %%
# Copy the views from the database created by the test runs to local dataframes
# Some views don't have UUIDS so mark those as wrong
test_dfs = {}
wrong_outputs = []
for s in successes['test_name']:
    test_table = pd.read_sql(f'SELECT * FROM analytics.{s}',conn)
    if not any(col in test_table for col in ['uuid','from_uuid','chv_uuid','chu_uuid']):
        # print(f'{s} does not contain uuid')
        wrong_outputs.append(s)
    else:
        test_dfs[s] = pd.read_sql(f'SELECT * FROM analytics.{s}',conn)


# %%
from ast import literal_eval

ge_results = pd.read_csv('generated_reports/ge_clean_results.csv')
ge_results.rename(columns={'result.short_name':'test_name'}, inplace=True)
ge_results['referenced_tables'] = ge_results['result.table'].apply(lambda x : [x])

ge_successes = ge_results[~ ge_results['error']][['test_name', 'referenced_tables']]
ge_errors = ge_results[~ ge_results['error']][['test_name','error']]


for test in ge_successes['test_name']:
    test_row = ge_results[ge_results['test_name'] == test]
    test_column = test_row['result.id_column'].values[0]
    error_value = test_row['result.unexpected_list'].apply(literal_eval).values[0]
    if test_column in ['uuid','from_uuid','chv_uuid','chu_uuid']:
        test_dfs[test] = pd.DataFrame(error_value, columns=[test_column])
    else:
        wrong_outputs.append(test)

# combine GE results with DBT results
successes = successes.append(ge_successes, ignore_index=True)
errors = errors.append(ge_errors, ignore_index=True)

successes = successes[~successes['test_name'].isin(wrong_outputs)]
wrong = pd.DataFrame(wrong_outputs, columns=['test_name'])
wrong['error'] = 'Output view does not contain UUID'
errors = errors.append(wrong, ignore_index=True)
#%%
tables = ['patient', 'assessment', 'assessment_follow_up', 'pregnancy', 
          'pregnancy_follow_up', 'postnatal_follow_up', 'chv', 'supervisor',
          'household','delivery','immunization']


tags = ['tag_' + r for r in tables]
for i in tables:
    successes['tag_' + i] = successes.apply(lambda x: int(i in x['referenced_tables']), axis=1)

# %%

ref_dfs = {}

for t in tables:
    ref_dfs[t] = pd.read_sql(f'SELECT * FROM {t}',conn)


# Iterating through each table in the database, pull out the relevant tests and put stats in a dataframe
OUTPUT_DIR = './generated_reports/'

table_outputs = []
test_outputs = []
for table in tables:
    # print(table)
    tests = successes[successes['tag_'+table]==1]['test_name'].to_list()
    if len(tests) == 0:
        continue
    dfs = [test_dfs[t] for t in tests]
    ref = ref_dfs[table]

    if table == 'chv':
        uuid_key = 'chv_uuid' #chv table has a different naming convention
    elif table == 'supervisor':
        uuid_key = 'chu_uuid' #supervisor table too!
    else:
        uuid_key = 'uuid'

    if 'reported' in ref:
        ## for tables that have a time associated with entries (not chv or supervisor)
        ## group by time and plot.
        ref['reported'] = pd.to_datetime(ref['reported'])
    
        plot_data = []
        for t,d in zip(tests, dfs):
            if 'reported' in d: # For tests on one table we have all the data we need
                subset = d
                subset['reported'] = pd.to_datetime(subset['reported'])
            elif uuid_key in d:
                subset = pd.merge(ref,d,on=uuid_key,how='inner',suffixes=('','_'))
            elif ('from_uuid' in d) or ('to_id' in d):
                referenced_tables = successes[successes['test_name']==t]['referenced_tables']
                key = 'from_uuid' if referenced_tables.iloc[0][0] == table else 'to_id'
                subset = pd.merge(ref,d,left_on=uuid_key,right_on=key,how='inner',suffixes=('','_'))
            subset_resamp = subset[subset['reported'].dt.year>=2017].groupby(pd.Grouper(key='reported',freq='1W'))[uuid_key].count()
            if subset.shape[0] != 0:
                plot_data.append((t, subset_resamp) )
                
        n_plots = len(plot_data)+1
        prop_cycle = plt.rcParams['axes.prop_cycle']
        colors = cycle(prop_cycle.by_key()['color'])
        fig, ax = plt.subplots(n_plots, 1, figsize=(10,n_plots*3),sharex=False)

        ref_resamp = ref[ref['reported'].dt.year>=2017].groupby(pd.Grouper(key='reported',freq='1W'))[uuid_key].count()
        ref_resamp.plot(ax=ax[0], label=table, color=next(colors))
        ax[0].legend(loc='upper left')
        ax[0].set_title(table, fontsize=18)
        
        for data,a in zip(plot_data,ax[1:]):
            t, resamp = data
            (resamp/ref_resamp).plot(ax=a, color=next(colors))
            a.set_title(t)
            a.set_ylabel('Fraction IoP')
        
        plt.tight_layout()
        plt.savefig(OUTPUT_DIR + table +'.png')
    
    
    test_output = []
    all_errors = []
    for t,d in zip(tests, dfs):
        if ('from_uuid' in d) or ('to_id' in d):
            referenced_tables = successes[successes['test_name']==t]['referenced_tables']
            key = 'from_uuid' if referenced_tables.iloc[0][0] == table else 'to_id'
        else:
            key = uuid_key
        row_errors = d[key].dropna().values.tolist()
        all_errors += row_errors
        test_output.append({
            'Test': t,
            'Table': table,
            'Errors': len(row_errors),
            '% Error': len(row_errors)/ref.shape[0]*100
        })
    test_outputs += test_output
    
    unique_errors = pd.Series(all_errors).nunique()
    
    table_output = {}
    table_output['Table'] = table
    table_output['Unique Rows with Error'] = unique_errors
    table_output['Total Rows'] = ref.shape[0]
    table_output['% Error'] = table_output['Unique Rows with Error']/table_output['Total Rows']*100
    table_outputs.append(table_output)
    
table_outputs = pd.DataFrame(table_outputs)
test_outputs = pd.DataFrame(test_outputs)

# print out everything you need to know
display = pd.options.display
display.max_columns = 1000
display.max_rows = 1000
display.max_colwidth = 199
display.width = None 

errors.to_csv('generated_reports/test_errors.csv')

print('TEST COVERAGE REPORT')
print('\n')
print('----------------Aggregate by Table-------------------\n')
print(table_outputs.set_index('Table'))
print('\n\n----------------Aggregate by Test-------------------\n')
print(test_outputs.set_index('Test'))
print('\n\n-------------------Test Errors----------------------\n')
print(errors.set_index('test_name'))