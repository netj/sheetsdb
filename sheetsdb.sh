#!/usr/bin/env bash
# sheetsdb -- a script for accessing Google Sheets as a database
# 
# Usage:
#  sheetsdb create SHEET COLUMN...
#  sheetsdb insert SHEET COLUMN=VALUE...
#  sheetsdb query  SHEET [GVIZ_QUERY]
#  sheetsdb export [csv|tsv] SHEET
#  sheetsdb export [pdf|zip|ods]
# 
# Sheetsdb is motivated by the pain in setting up database servers even for the
# simplest data collection tasks, and inspired by several blog posts:
# - http://acrl.ala.org/techconnect/?p=4001
# - http://blog.ouseful.info/2009/05/18/using-google-spreadsheets-as-a-databace-with-the-google-visualisation-api-query-language/
# - https://mashe.hawksey.info/2014/07/google-sheets-as-a-database-insert-with-apps-script-using-postget-methods-with-ajax-example/
# 
# The Google Sheets query language reference:
# - https://developers.google.com/chart/interactive/docs/querylanguage
#
# Author: Jaeho Shin <netj@cs.stanford.edu>
# Created: 2015-01-28
set -eu

warn()  { echo >&2 "$@"; }
error() { warn "$@"; false; }
usage() {
    sed -n '2,/^#$/ s/^# //p' <"$0"
    [[ $# -eq 0 ]] || error "$@"
}

[[ $# -ge 1 ]] || {
    # show usage unless we have enough arguments
    usage "$0"
    exit 1
}

# Working with a sample sheet
SHEETSDB_READ_KEY=1y212-CLet7mHPYmFhDtDBO1xob-UNXlZpbbV99PMKhk
SHEETSDB_WRITE_KEY=AKfycbxbZhav5_AHMEAW-3g7uSe0hqaEgi7Uiay4n-RAt69DOY-t0ixW

# default settings
: \
    ${SHEETSDB_READ_KEY:?should be set to the id of the Google Sheets document visible to anyone via link} \
    ${SHEETSDB_WRITE_KEY:?should be set to the id of the Google Apps Script deployed as a web-app} \
    ${SHEETSDB_HEADER_ROW:=1} \
    ${SHEETSDB_OUTPUT_FORMAT:=csv} \
    ${SHEETSDB_USING_OLD_SHEET:=} \
    ${SHEETSDB_EXPORT_FILE:=} \
    #

curlOpts=(
    --silent --show-error
    --location  # follow redirects
)
getURL() {
    local url=$1; shift
    local dataArgs= arg=
    dataArgs=(); for arg; do dataArgs+=(--data-urlencode "$arg"); done
    curl "${curlOpts[@]}" --get "$url" "${dataArgs[@]:-}"
}
downloadURL() {
    local filename=$1; shift
    local curlOpts=( "${curlOpts[@]}" --no-silent --progress-bar )
    case $filename in
        "")
            curlOpts+=( --remote-name )
            ;;
        *)
            curlOpts+=( --output "$filename" )
    esac
    getURL "$@"
}

Mode=$1; shift
case $Mode in
    c|create)
        # TODO create a new sheet
        args=( action=create )

        # sheet name
        [[ $# -gt 0 ]] || usage "SHEET to create must be specified"
        Sheet=$1; shift
        args+=( sheet="$Sheet" )
        # column names and types
        for arg; do
            case $arg in
                *:*)
                    args+=( ".$arg" )
                    ;;
                *)
                    error "$arg: Unrecognized argument to create"
            esac
        done

        updateURL="https://script.google.com/macros/s/$SHEETSDB_WRITE_KEY/exec"
        getURL "$updateURL" "${args[@]}"
        ;;

    i|insert)
        args=( action=insert )

        # sheet name
        [[ $# -gt 0 ]] || usage "SHEET to insert must be specified"
        Sheet=$1; shift
        args+=( sheet="$Sheet" )
        # header row
        args+=( headers="${SHEETSDB_HEADER_ROW}" )
        # column names and values
        # TODO support multiple row insertion
        for arg; do
            case $arg in
                *=*)
                    args+=( "data.$arg" )
                    ;;
                *)
                    error "$arg: Unrecognized argument to insert"
            esac
        done

        updateURL="https://script.google.com/macros/s/$SHEETSDB_WRITE_KEY/exec"
        getURL "$updateURL" "${args[@]}"
        ;;

    q|query)
        # collect arguments for HTTP request to Google Docs
        args=()

        # sheet name
        [[ $# -gt 0 ]] || usage "SHEET to query must be specified"
        Sheet=$1; shift
        args+=( sheet="$Sheet" )
        # header row
        args+=( headers="${SHEETSDB_HEADER_ROW}" )
        # optional query
        if [[ $# -gt 0 ]]; then
            args+=( tq="$1" ); shift
        fi
        # output format
        # See: https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat
        case $SHEETSDB_OUTPUT_FORMAT in
            csv|html|tsv-excel)
                args+=( tqx="out:$SHEETSDB_OUTPUT_FORMAT" )
                ;;
            json)
                args+=( tqx="out:json;responseHandler:onData" )
                ;;
            *:*|*\;*)
                args+=( tqx="$SHEETSDB_OUTPUT_FORMAT" )
                ;;
            *)
                error "$SHEETSDB_OUTPUT_FORMAT: Unrecognized SHEETSDB_OUTPUT_FORMAT"
        esac

        # send a request to Google Docs
        gvizURL="https://docs.google.com/spreadsheets/d/$SHEETSDB_READ_KEY/gviz/tq"
        if [[ -n "$SHEETSDB_USING_OLD_SHEET" ]]; then
            # fallback to old URL
            # See: https://code.google.com/p/google-visualization-api-issues/issues/detail?id=1476
            gvizURL="https://spreadsheets.google.com/tq"
            args+=( key="$SHEETSDB_READ_KEY" )
        fi
        getURL "$gvizURL" "${args[@]}"
        ;;

    e|export)
        args=()
        Format=${1:-zip}; shift || true
        case $Format in
            tsv|csv)
                # sheet name
                [[ $# -gt 0 ]] || usage "SHEET to export must be specified"
                Sheet=$1; shift
                # FIXME this does not work
                args+=( sheet="$Sheet" )
                download=false
                ;;
            zip|ods|pdf)
                download=true
                ;;
            *)
                error "$Format: Unrecognized export format"
        esac
        args+=( format="$Format" )
        exportURL="https://docs.google.com/spreadsheets/d/$SHEETSDB_READ_KEY/export"
        if $download; then
            filename="${SHEETSDB_EXPORT_FILE:-sheetsdb-export-$(date +%Y%m%d_%H%M%S).$Format}"
            downloadURL "$filename" "$exportURL" "${args[@]}"
            echo "$filename: exported"
        else
            getURL "$exportURL" "${args[@]}"
        fi
        ;;
esac
