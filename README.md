# sheetsdb
A command-line interface to Google Sheets to use it as a relational database.

## Quick Start
1. Make a copy of [the spreadsheet designed for sheetsdb][sheetsdb doc].
2. Follow the setup instructions shown in the sheetsdb sheet.
3. Copy the environment variables `SHEETSDB_KEY_READ` and `SHEETSDB_KEY_WRITE` and export them from your shell.
4. Use the `sheetsdb` command to access and manipulate the spreadsheet contents from anywhere.

[sheetsdb doc]: https://docs.google.com/spreadsheets/d/1y212-CLet7mHPYmFhDtDBO1xob-UNXlZpbbV99PMKhk

## Features

### Data Definition
* `sheetsdb create SHEET_NAME COLUMN_NAME:TYPE...` to create a new sheet with specified columns and their types.
    * Valid `TYPE` is one of:
        * `text` or `string`
        * `int` or `number`
        * `float` or `double`
        * `datetime`, `date`, `time`, or any [SimpleDateFormat string][]
* `sheetsdb drop SHEET_NAME` (TODO)
* `sheetsdb rename SHEET_NAME NEW_SHEET_NAME` (TODO)

### Data Manipulation
* `sheetsdb q SHEET_NAME` to list all rows in a sheet.
    * `SHEETSDB_OUTPUT_FORMAT` environment can be set to change the output format to one of the following:
        * `csv` (default)
        * `html`
        * `json`
* `sheetsdb q SHEET_NAME GVIZ_QUERY` to run a query written in [Google Visualization API Query Language][GVizQL] over a sheet.
    * For example, `sheetsdb q Foo "SELECT COUNT(A) GROUP BY B"`
* `sheetsdb update SHEET_NAME NAME=VALUE... where NAME=VALUE...` (TODO)

### Data Dump/Loading
* `sheetsdb export FORMAT SHEET_NAME` to export one sheet
    * where `FORMAT` is one of:
        * `tsv`
        * `csv`
* `sheetsdb export FORMAT` to export all sheets
    * where `FORMAT` is one of:
        * `zip`
        * `pdf`
        * `ods`
    * `SHEETSDB_EXPORT_FILE` environment can be set to a destination file path.
* `sheetsdb import FORMAT PATH` (TODO)

[SimpleDateFormat string]: http://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html
[GVizQL]: https://developers.google.com/chart/interactive/docs/querylanguage


## References
Following articles gave inspiration to writing sheetsdb:

* [Query a Google Spreadsheet like a Database with Google Visualization API Query Language](http://acrl.ala.org/techconnect/?p=4001) by Bohyun Kim
* [Using Google Spreadsheets as a Database with the Google Visualisation API Query Language](http://blog.ouseful.info/2009/05/18/using-google-spreadsheets-as-a-databace-with-the-google-visualisation-api-query-language/) by Tony Hirst
* [Google Sheets as a Database – INSERT with Apps Script using POST/GET methods (with ajax example)](https://mashe.hawksey.info/2014/07/google-sheets-as-a-database-insert-with-apps-script-using-postget-methods-with-ajax-example/) by Martin Hawksey
