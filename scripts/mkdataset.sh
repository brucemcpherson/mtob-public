MODE=$1
DS="cx_ds_${1}"
echo "...making dataset ${DS}"
bq mk --location=eu ${DS}