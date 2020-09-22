#!/bin/bash


function services() {
	local ORG=$1
	local SPACE=$2
    #echo "# searching services in $ORG org, $SPACE space"
	ALL_SERVICES=$(cf services | awk 'NR > 3 {print $1}')
	if [ -z $ALL_SERVICES ]; then
		echo "NO SERVICE in '$ORG' org, '$SPACE' space"
		echo ""
		return 0
	fi

	for SERVICE in $ALL_SERVICES
	do
	echo "============================================================================="
	echo "FOUND SERVICE in '$ORG' org, '$SPACE' space =>  '$SERVICE' service"
	echo "  $(cf service $SERVICE | awk 'NR >3 ')"
	echo " guid: $(cf service $SERVICE --guid)"
	echo "-----------------------------------------------------------------------------"
	done
}


function spaces(){
	local ORG=$1
	cf target -o $ORG  > /dev/null
	ALL_SPACES=$(cf spaces | awk 'NR > 3')
	#echo "# ALL_SPACES: $ALL_SPACES"
	for SPACE in $ALL_SPACES
	do
		cf target -o $ORG -s $SPACE > /dev/null
		#cf services | awk 'NR > 3';
		services $ORG $SPACE
	done
}

cf target

ALL_ORGS=$(cf orgs | awk 'NR > 3')
for ORG in $ALL_ORGS; do
  spaces $ORG
done