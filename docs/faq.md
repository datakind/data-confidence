# Frequently Asked Questions and Common Problems

## Where does this stack look for raw data, and where does it load the data it creates

By default, raw data will be extracted from the `public` schema in whatever postgres database you've configured in [your `profiles.yml` file](./getting_started.md#configuring_dbt). Once processed by the DBT modelling process, data will be written out to another schema in the same database. By default, DBT names this schema `analytics`, but you can change the name to whatever you want as long as you make the corresponding changes in `profiles.yml` and `dbt_project.yml`

## My data is stored in a different format than these tests are expecting

It's highly likely that your data will look slightly different than the data we used to create this stack. Modifiying the SQL queries in `dbt/models/core` to restructure the data into a format aligned with what the tests are expecting is the easiest way to get running quickly. Both the DBT and Great Expectations tests reference these core models, so you'll only need to make these changes once for both sides of the stack.

## How does logging work in this stack

Since different organizations handle logging in a variety of ways, we've deliberately not been prescriptive with how logs in this stack are created at this point. Both DBT and Great Expectations create minimal logs on their own in their respective directories, but the stack does not reference these. When running scripts (like `run_everything.sh`) or commands (like `dbt test -m core`), output will naturally be streamed to stdout and can be easily piped into a file for basic observability.

## How does permissioning work

At present, this stack assumes a single postgres user that has both read and write priviledges. If this isn't compatible with the data access setup at your organization, you might consider creating a new user specifically to run this stack with access limited only to the tables and schemas in question.
