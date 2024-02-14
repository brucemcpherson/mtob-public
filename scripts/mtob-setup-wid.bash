
#!/bin/bash

NS=$1
if [ -z "${NS}" ]; then
  echo "first arg should be a namespace like gcp-prod"
  exit 1
fi


REGION="yourregion"
CLUSTERNAME="yourcluster"
KSA="mtob-robot-${NS}"
PROJECT="yourproject"
GSANAME="mtob-gsa-${NS}"
GSA="${GSANAME}@${PROJECT}.iam.gserviceaccount.com"
EXPIRE="+5 years"
TITLE="Temporary sa for mongo to bigquery"
TS=$(date -d "+${EXPIRE}" --utc +%FT%TZ)
TEMP=$(mktemp)



# make conditions for iam binding
jq -n ' {"expression": $E, title: $T, description: $D}' \
  --arg T "${TITLE}"  \
  --arg E "request.time < timestamp('${TS}')"  \
  --arg D "expires at ${TS}" > $TEMP

# get to the right cluster and ns
gcloud container clusters get-credentials ${CLUSTERNAME} \
    --region=${REGION}

kubectl config set-context --current --namespace=${GCP_STG}

# create a kiube service account
KL=$(kubectl get serviceaccount -n ${NS}| grep ${KSA})
if [ -n "${KL}" ]; then
  kubectl delete serviceaccount ${KSA} \
    --namespace ${NS} 
fi

kubectl create serviceaccount ${KSA} \
    --namespace ${NS}

# create service account and give it required roles
SL=$(gcloud iam service-accounts list | grep ${GSA})
if [ -n "${SL}" ]; then
  gcloud iam service-accounts delete ${GSA} --quiet
fi

gcloud iam service-accounts create ${GSANAME} \
    --project=${PROJECT} \
    --display-name="GCP SA ${GSANAME} for use with kube ${KSA} for mongo to bq"

# roles required for storage and bigquery to be assigned to gcp service account
ROLES=('bigquery.dataEditor' 'bigquery.user' 'storage.objectAdmin')


# assign each of the required rolews
for role in "${ROLES[@]}"
do
  gcloud projects add-iam-policy-binding ${PROJECT} \
    --member "serviceAccount:${GSA}" \
    --role "roles/${role}" \
    --condition-from-file=${TEMP}
done


# assign it to kube sa
gcloud iam service-accounts add-iam-policy-binding ${GSA} \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT}.svc.id.goog[${NS}/${KSA}]" 

# see https://stackoverflow.com/questions/57241357/metadataserverexception-when-using-gke-workload-identity/58205952#58205952
#gcloud iam service-accounts add-iam-policy-binding ${GSA} \
#    --role roles/iam.serviceAccountTokenCreator \
#    --member "serviceAccount:${PROJECT}.svc.id.goog[${NS}/${KSA}]" 

kubectl annotate serviceaccount ${KSA} \
    --namespace ${NS} \
    iam.gke.io/gcp-service-account=${GSA} \
    --overwrite

# clean up
rm $TEMP