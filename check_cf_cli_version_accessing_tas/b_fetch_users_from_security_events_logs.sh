#!/bin/bash
set -x

#### input: exploded bosh logs files under ./tmp after running 1_explode_bosh_logs.sh
#### output: - ./tmp/output_b_fetch_users_from_security_events_logs.txt
####           all entry from system user will be excluded from output file.

start_time="$(date -u +%s)"

work_dir="./tmp"

script_filename=$(basename $0 ".sh" )
OUTPUT_FILE="$work_dir/output_$script_filename.txt"

echo "STARTING: gathering all entries(timestamp, suser, suid, vcap_request_id) from security_events.log..."

## gather all entries, sort by latest events first.
find $work_dir -name "security_events.log*" | xargs egrep -a 'suser=[a-zA-Z0-9]' \
| grep -v -e "suser=system_services" -e "suser=healthwatch_sli_test" -e "suser=push_apps_manager"  -e "suser=MYSQL" \
| awk  '{print $2 " " $10 " " $11 " " $19}' | grep cs2   | sort -r > $OUTPUT_FILE
entry_count=$(cat $OUTPUT_FILE | wc -l)
echo "COMPLETED: gathering all entries from security_events.log:  ($entry_count) $OUTPUT_FILE"

end_time="$(date -u +%s)"
elapsed=$(( $end_time - $start_time ))
echo "Elapsed time: $elapsed seconds"