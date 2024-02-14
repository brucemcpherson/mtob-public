MODE=$1
TABLE=$2
DS="cx_ds_${1}"
bq show --format json ${DS}.${TABLE} | jq '.schema.fields' > schemas/${MODE}-${TABLE}.json