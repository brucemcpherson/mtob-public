
# set up workload identity service accounts for mtob
NS=$1
if [ -z "${NS}" ]; then
  echo "first arg should be a namespace like gcp-prod"
  exit 1
fi
# this needs to be run under bash
bash mtob-setup-wid.bash "${NS}"
