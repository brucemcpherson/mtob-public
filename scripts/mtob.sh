
# usage mode table (e.g stg collectionname)
# you also need to be logged into doppler
MODE=$1
TABLE=$2
DS="cx_ds_${MODE}"
BUCKET="gs://cx-bq-transfer"
FOLDER="/exmongo"
TEMP=$(mktemp)
TEMP2=$(mktemp)
FILE=${TABLE}.ndjson
PREFIX="/exmongo/${MODE}"
SCHEMA="./schemas/prod-${TABLE}.json"
NS="gcp-${MODE}"

# 1- extract from mongo
echo "exporting ${FILE} and cleaning ${TEMP}"

# these DB_ come from kube secrets in env
HOST="mongodb+srv://${DB_HOST}"
CONNECTION="${HOST}/${DB_NAME}"

# get files out of mongo
mongoexport  --uri "${CONNECTION}" --username "${DB_USER}" --password "${DB_PASSWORD}" --type=json -c "${TABLE}" -o "${TEMP}"

cat "${TEMP}" |  sed -E s/"\\$/"/g > "${TEMP2}"
rm "${TEMP}"

# for example mtobq prod collectionname
URI="${BUCKET}${PREFIX}/${FILE}"

echo "...moving ${FILE} to ${URI}"
gsutil mv ${TEMP2} ${BUCKET}${PREFIX}/${FILE}

# now to bq
echo "...loading ${URI} to bigquery table ${DS}.${TABLE} with schema ${SCHEMA}"

bq --location=eu load \
--replace \
--autodetect \
--source_format=NEWLINE_DELIMITED_JSON \
"${DS}.${TABLE}" \
"${URI}" \
"${SCHEMA}"

