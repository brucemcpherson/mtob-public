NS=$1
if [ -z "${NS}" ]; then
  echo "first arg should be a namespace like gcp-prod"
  exit 1
fi
kubectl config set-context --current --namespace=${NS}