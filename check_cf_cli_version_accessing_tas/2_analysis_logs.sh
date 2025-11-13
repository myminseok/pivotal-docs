#!/bin/bash
set +x

echo ""
echo "a_fetch_cf7_request_id_from_nginx_access_logs.sh"
./a_fetch_cf7_request_id_from_nginx_access_logs.sh

echo ""
echo "b_fetch_users_from_security_events_logs.sh"
./b_fetch_users_from_security_events_logs.sh

echo ""
echo "c_find_cf7_user.sh"
./c_find_cf7_user.sh
