#!/bin/bash
set +x

#### input: exploded bosh logs files under ./tmp after running 1_explode_bosh_logs.sh
#### output: ./tmp/output_a_fetch_cf7_request_id_from_nginx_access_logs.txt

start_time="$(date -u +%s)"

work_dir="./tmp"
script_filename=$(basename $0 ".sh" )
OUTPUT_FILE="$work_dir/output_$script_filename.txt"

echo "STARTING: gathering all entries from nginx-access.log ..."

echo "  making cache file for entries (timestamp, cf cli version, vcap_request_id) from nginx-access.log "
#find $work_dir -name "nginx-access.log*" | xargs egrep -a 'cf/7|cf7/7' | awk  '{print $3 " " $11 " " $17}' | sort > $OUTPUT_FILE
find $work_dir -name "nginx-access.log*" | xargs egrep -a 'cf/7|cf7/7' | awk  '{print $17 " " $11 " " $3}' | grep "vcap_request_id" | sed 's/vcap_request_id://' | sort > $OUTPUT_FILE

if [ -f $OUTPUT_FILE ]; then
  count=$(cat $OUTPUT_FILE | wc -l)
  echo "COMPLETED: gathering all entries from nginx-access.log : total ($count) $OUTPUT_FILE"
else
  echo "COMPLETED: gathering all entries from nginx-access.log : NO RECORD "
fi
end_time="$(date -u +%s)"
elapsed=$(( $end_time - $start_time ))
echo "Elapsed time: $elapsed seconds"