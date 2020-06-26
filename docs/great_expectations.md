# Testing in Great Expectations

## Writing custom expectations

Custom expectations operate under a few basic principles described in a page from the [Great Expectations documentation](https://docs.greatexpectations.io/en/latest/how_to_guides/creating_and_editing_expectations/spare_parts/how_to_create_custom_expectations.html). It might be best to refer to the examples provided in this [repository](../great_expectations/plugins/custom_expectations.py) to get a sense of what goes into writing one.

Highlights about writing custom expectations:
* It's best to write expectations that take in arguments about columns and tables to query. The template to query data in an universal way looks like this:
```python

    @DataAsset.expectation(["quantity", "key", "form_name"])
    def expect_something(self, quantity, key, form_name):
        rows_query = sa.select([
            sa.column(quantity),
            sa.column(key)
        ]).select_from(sa.Table(form_name, self._table.metadata))

        rows_df = pd.read_sql(rows_query, self.engine)
        ...
```
Note the decorator telling Great Expectations the arguments that can be passed to the custom expectation. Also, if an expectation is very specific to a set of tables and columns, those do not need to be passed as arguments since it's likely not reusable for a different set of data.

* Custom expectations offered as examples here return extra information (such as row UUIDs and source table) to create views as part of the Data Integrity framework. Built-in expectations don't offer that capability, but there are two ways to deal with that: 1) DBT offers a straighforward way to reproduce well most of the functionality offered by the built-in expectations, and 2) creating a custom expectation inspired by a built-in expectation and changing its output to match what you need is also straightforward. 

## Expected output

To best leverage the capabilities of the Data Integrity framework, we recommend a minimum set of fields in the output of the expectations. The results from Great Expectations are free-form, and users are free to add as many fields as required for their needs, but some fields are required for specific post-processing steps. The following shows a description of the field and a sample output from a custom expectation:

* `table` as the name of the table where rows containing IoP data can be referred to  
* `id_column` as the name of the column containing unique (or unique enough) identifiers in the aforementioned table, to create a view out of the rows containing IoP data
* `unexpected_list` as a list of uuids found in the `id_column` previously defined (associated with the relevant rows)
* `short_name` is the name of the view created as a result of failing that custom expectation, with two guidelines: keep the name under 40 characters, and prefix it with `chv_` is the rows returned are health workers IDs rather than IDs about visits, measurements, etc.
* `success` (a boolean) and `result` (a dictionary) are expected by Great Expectations (refer to the sample output below)

Sample:

```python
{
  "success": len(failing_uuids) == 0,
  "result": {
      "unexpected_list": failing_uuids,
      "table": table_where_records_originate,
      "id_column": unique_identifier_for_failing_records,
      "short_name": f"the_name_for_the_view_showing_failing_records"
      }
}
```
