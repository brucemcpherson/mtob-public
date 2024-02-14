# create a job for mtob
NS=$1
if [ -z "${NS}" ]; then
  echo "1st arg should be namespace eg gcp-stg"
  exit 1
fi

CRON="mtob-cron"

# delete current version of job if it exists
C=$(kubectl get cronjobs -n ${NS} | grep "${CRON}")
if [ -n "${C}" ]; then
  kubectl delete cronjob ${CRON} -n ${NS}
fi

# the job template
FILE="${CRON}.yaml"

# the kubice account name
KSA="mtob-robot-${NS}"

# build the spec and apply
yq e ".metadata.namespace = \"${NS}\"" $FILE | \
  yq e ".spec.jobTemplate.spec.template.spec.serviceAccountName = \"${KSA}\"" - | \
  kubectl apply -f -
