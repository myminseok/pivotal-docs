#!/bin/bash
set -x
shopt -s expand_aliases
source ~/.profile

DEPLOYMENT="${1}"
#DEPLOYMENT="cf-edc5e09298dc349e5048"
if [ -z "$DEPLOYMENT" ]; then
  echo "DEPLOYMENT name is required"
  echo "  Usage: $0 DEPLOYMENT"
  exit 1
fi

bosh -d $DEPLOYMENT vms  | grep diego_cell | awk '{print $1 " " $4}' > ./tmp_diego_cell_ip_${DEPLOYMENT}.txt

while IFS= read line || [ -n "$line" ]; do
    if [[ "$line" == "#"* || "$line" == "" ]]; then
        continue
    fi
    ## trim leading /trailing whitespace
    line=$(echo "$line" | xargs)
    #echo "$line"
    instance=$(echo "$line" | awk '{print $1}')
    echo "$instance"
    ip=$(echo "$line" | awk '{print $2}')
    echo "$ip"

    bosh -d $DEPLOYMENT ssh ${instance} -c "sudo; source /var/vcap/jobs/cfdot/bin/setup ; cfdot actual-lrps> /tmp/diego_cell_cfdot_actual_lrps.json"
 
    # copy the json to local directory
    bosh -d $DEPLOYMENT scp ${instance}:/tmp/diego_cell_cfdot_actual_lrps.json "./diego_cell_cfdot_actual_lrps_${DEPLOYMENT}_${ip}.json"

    # parse app,space,org name from the json.
    jq ".metric_tags| [.app_name, .space_name, .organization_name ]" ./diego_cell_cfdot_actual_lrps_${DEPLOYMENT}_${ip}.json

done < ./tmp_diego_cell_ip_${DEPLOYMENT}.txt

