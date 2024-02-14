# create a job for mtob
NS=$1
if [ -z "${NS}" ]; then
  echo "1st arg should be namespace eg gcp-stg"
  exit 1
fi

JOB=mtob-job

# delete current version of job if it exists
C=$(kubectl get jobs -n ${NS} | grep "${JOB}")
if [ -n "${C}" ]; then
  kubectl delete job ${JOB} -n ${NS}
fi

# the job template
FILE="${JOB}.yaml"

# the kubice account name
KSA="mtob-robot-${NS}"

# build the spec and apply
yq  e ".metadata.namespace = \"${NS}\"" $FILE | \
  yq e ".spec.template.spec.serviceAccountName = \"${KSA}\"" - | \
  kubectl apply -f -
