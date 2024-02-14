#!/bin/bash

# this comes from the kube yaml file env
echo "Running in namespace ${NAMESPACE}"

# extract the mode 
MODE=$(echo $NAMESPACE | sed -E s/^.*-//)
echo "...running mode ${MODE} on namespace ${NAMESPACE}"

# run all the tables in this ns
COLLECTIONS=(
  'c1' 'c2' 'c3'
)
GOOD=0
BAD=0

for c in "${COLLECTIONS[@]}"
do
  echo ""
  echo "----working on collection ${c}----"
  sh mtob.sh "${MODE}" "${c}"
  if [ $? -ne 0 ]; then
    echo "ERROR - failed on collection ${c}"
    let "BAD++"
  else 
    echo "...finished on collection ${c}"
    let "GOOD++"
  fi
done

echo ""
echo "----all done----"
echo "loaded ${GOOD} from ${#COLLECTIONS[@]} collections from mongo to bigquery"
if [ $BAD -ne 0 ]; then
  echo "ERROR there were ${BAD} failures"
  exit 88
else
  exit 0
fi

