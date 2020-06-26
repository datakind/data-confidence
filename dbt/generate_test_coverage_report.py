import json
from itertools import chain 

import numpy as np
import pandas as pd
pd.set_option('display.max_columns', None)
from pandas.io.json import json_normalize


with open('target/run_results.json') as f:
    run_results = json.load(f)
    
results = json_normalize(run_results['results'])

# Get rid of verbose columns we don't need
results.drop(list(results.filter(regex = '_sql')), axis = 1, inplace = True)
results.drop(list(results.filter(regex = '_path')), axis = 1, inplace = True)

# Unravel nested list of refs and add tag columns
results['node.refs.unpacked'] = results['node.refs'].apply(chain.from_iterable).apply(list)
possible_refs = list(set(results['node.refs.unpacked'].apply(lambda x:pd.Series(x)).stack()))
for i in possible_refs:
    results['tag_' + i] = results.apply(lambda x: int(i in x['node.refs.unpacked']), axis=1)
    
    
def print_test_results_for_df(df, title=''):
    output = {}
    output['Data Source'] = title
    output['Total tests run'] = len(df)
    output['Passed'] = len(df) - df[['fail','warn','error']].notnull().any(1).sum()
    output['Failed'] = df['fail'].sum()
    output['Warning'] = df['warn'].sum()
    # "Error" state indicates a problem with the test itself, not that there were records that passed or failed      
    output['Error'] = df['error'].notnull().sum()
    output['Skipped'] = df['skip'].sum()
    output['IoP Records'] = pd.to_numeric(df['status'], errors='coerce').sum()
    
    return output

print()
print('IOP TEST COVERAGE REPORT')
print()
print('----- Summary ----- ')
summary = print_test_results_for_df(results)
[print('{0}: {1}'.format(i,summary[i])) for i in summary if i != 'Data Source']
print()
list_of_outputs = []
for i in possible_refs:
    col = 'tag_' + i
    list_of_outputs.append(print_test_results_for_df(results[results[col] == 1], title = i))

print('----- Details ----- ')
output = pd.DataFrame(list_of_outputs)
output.set_index('Data Source', inplace=True)
print(output.sort_values('Total tests run', ascending=False))
print()