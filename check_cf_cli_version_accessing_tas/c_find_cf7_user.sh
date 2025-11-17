#!/bin/bash
set +x

#### input: - ./tmp/output_b_fetch_users_from_security_events_logs.txt
####        - ./tmp/output_a_fetch_cf_request_id_from_nginx_access_logs.txt
#### output: - ./tmp/output_c_find_cf7_user.txt

work_dir="./tmp"
script_filename=$(basename $0 ".sh" )
INPUT_SECURITY_FILE="$work_dir/output_b_fetch_users_from_security_events_logs.txt"
TMP_CF_ACCESS_FILE="$work_dir/output_a_fetch_cf7_request_id_from_nginx_access_logs.txt"
TMP_OUTPUT_FILE="$work_dir/output_${script_filename}_tmp.txt"
OUTPUT_FILE="$work_dir/output_${script_filename}.txt"

echo "STARTING: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log) ..."

if [ ! -f $INPUT_SECURITY_FILE ]; then
   echo " file not found : $INPUT_SECURITY_FILE"
   exit 1
fi
if [ ! -f $TMP_CF_ACCESS_FILE ]; then
   echo " file not found : $TMP_CF_ACCESS_FILE"
   exit 1
fi

echo "  total users input entries from $INPUT_SECURITY_FILE : $(cat $INPUT_SECURITY_FILE | wc -l)"
echo "  total cf cli input entries from  $TMP_CF_ACCESS_FILE : $(cat $TMP_CF_ACCESS_FILE | wc -l)"

## join and print except request_id($1)
join -1 1 -2 1 $INPUT_SECURITY_FILE $TMP_CF_ACCESS_FILE | awk '{print $2 " " $3 " " $4 " "  $5 }' | sort | uniq > $TMP_OUTPUT_FILE
## print except timestamp($4) to deduplicate
cat $TMP_OUTPUT_FILE| awk '{print $1 " " $2 " " $3  }' | sort | uniq > $OUTPUT_FILE

entry_count=$(cat $OUTPUT_FILE | wc -l)
if [ -f $OUTPUT_FILE ]; then
  echo "COMPLETED: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log): total ($entry_count)  $OUTPUT_FILE"
else
  echo "COMPLETED: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log): NO MATCHED RECORD FOUND"
fi
