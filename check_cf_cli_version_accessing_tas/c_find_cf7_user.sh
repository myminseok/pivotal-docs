#!/bin/bash
set +x

#### input: - ./tmp/output_b_fetch_users_from_security_events_logs.txt
####        - ./tmp/output_a_fetch_cf_request_id_from_nginx_access_logs.txt
#### output: - ./tmp/output_c_find_cf7_user.txt

work_dir="./tmp"
script_filename=$(basename $0 ".sh" )
INPUT_SECURITY_FILE="$work_dir/output_b_fetch_users_from_security_events_logs.txt"
TMP_CF_ACCESS_FILE="$work_dir/output_a_fetch_cf7_request_id_from_nginx_access_logs.txt"
OUTPUT_FILE="$work_dir/output_$script_filename.txt"

echo "STARTING: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log) ..."

if [ ! -f $INPUT_SECURITY_FILE ]; then
   echo " file not found : $INPUT_SECURITY_FILE"
   exit 1
fi
if [ ! -f $TMP_CF_ACCESS_FILE ]; then
   echo " file not found : $TMP_CF_ACCESS_FILE"
   exit 1
fi


entry_count=$(cat $INPUT_SECURITY_FILE | wc -l)
echo "  total input entries from $INPUT_SECURITY_FILE : $entry_count"


cf_entry_count=$(cat $TMP_CF_ACCESS_FILE | wc -l)
echo "  total input entries from  $TMP_CF_ACCESS_FILE : $cf_entry_count"
rm -rf $OUTPUT_FILE
touch $OUTPUT_FILE
found=0
index=0
found_suser_array=()
previously_gathered_user=""
while IFS= read line || [ -n "$line" ]; do
     ((index++))
      if [[ "$line" == "#"* || "$line" == "" ]]; then
         continue
      fi

      suser=$(echo $line | awk '{print $2}' | sed 's/suser=//')

      if [ "$suser" == "$previously_gathered_user" ]; then
          echo -ne "   ($entry_count/$index/$found) skipping '$suser' previously gathered  \
                                                                                        "\\r
          continue
      fi

      timestamp=$(echo $line | awk '{print $1}')
      request_id=$(echo $line | awk -F 'cs2=' '{print $2}')

      alreadyGathered=false
      for element in "${found_suser_array[@]}"; do
        if [[ "$element" == "$suser" ]]; then
           alreadyGathered=true
           break
        fi
      done
      if "$alreadyGathered"; then
         echo -ne "   ($entry_count/$index/$found) skipping '$suser' already gathered $timestamp   \
                                                                                        "\\r
         continue
      fi

      cf_cli_info=$(grep -a "$request_id" $TMP_CF_ACCESS_FILE | awk '{print $2}')
      if [[ "$cf_cli_info" == "" ]]; then
          echo -ne "   ($entry_count/$index/$found) skipping; no match $timestamp $request_id"\\r
          continue
      fi

      echo "$line $cf_cli_info" >> $OUTPUT_FILE
      previously_gathered_user="$suser"
      found_suser_array+=("$suser")
       
      ((found++))
      echo -ne "    ($entry_count/$index/$found) adding $timestamp $suser"\\r
done < $INPUT_SECURITY_FILE
echo ""

if [ -f $OUTPUT_FILE ]; then
  echo "COMPLETED: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log): total ($found)  $OUTPUT_FILE"
else
  echo "COMPLETED: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log): NO MATCHED RECORD FOUND"
fi
