# qsv

> A high-performance CSV data-wrangling toolkit written in Rust.
> The spiritual successor to `xsv`, with SQL and Excel support.
> More information: <https://github.com/dathere/qsv>.

- Inspect the headers of a CSV file:

`qsv headers {{path/to/file.csv}}`

- Count the number of records:

`qsv count {{path/to/file.csv}}`

- Get an overview of the shape and per-column statistics:

`qsv stats {{path/to/file.csv}} | qsv table`

- Select a few columns by name or index:

`qsv select {{column1,column2}} {{path/to/file.csv}}`

- Show a random sample of records:

`qsv sample {{10}} {{path/to/file.csv}}`

- Filter rows whose column matches a regex:

`qsv search --select {{column}} {{pattern}} {{path/to/file.csv}}`

- Join two CSV files on a column:

`qsv join {{column1}} {{path/to/file1.csv}} {{column2}} {{path/to/file2.csv}}`

- Run a SQL query across one or more CSV files (via Polars):

`qsv sqlp {{path/to/file.csv}} '{{SELECT col, COUNT(*) FROM _t_1 GROUP BY col}}'`
