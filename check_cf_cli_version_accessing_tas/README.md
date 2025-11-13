
Following document describes how to list up any cf cli accessing the platform with old version, such as cf cli version 7.


Tested on TAS 6

## Procedure

#### Step 0. Download platform logs from cloud_controller groups.
bosh -d CF_DEPLOYMENT logs cloud_controller

```
bosh -d cf-05c0b7494ba8ddb50eb8 logs cloud_controller
```

now the bosh log archive file is located as following.
```
ls -al

drwxr-xr-x@ 12 kminseok  staff       384 Nov 13 20:30 .
drwxr-xr-x@ 54 kminseok  staff      1728 Nov 12 16:39 ..
-rwxr-xr-x@  1 kminseok  staff      1103 Nov 13 20:34 1_explode_bosh_logs.sh
-rwxr-xr-x@  1 kminseok  staff       295 Nov 13 20:33 2_analysis_logs.sh
-rw-r--r--@  1 kminseok  staff      5725 Nov 13 20:32 README.md
-rwxr-xr-x@  1 kminseok  staff       969 Nov 13 20:33 a_fetch_cf7_request_id_from_nginx_access_logs.sh
-rwxr-xr-x@  1 kminseok  staff      1076 Nov 13 20:33 b_fetch_users_from_security_events_logs.sh
-rwxr-xr-x@  1 kminseok  staff      3033 Nov 13 20:21 c_find_cf7_user.sh
-rw-------@  1 kminseok  staff  86272707 Nov 12 17:09 cf-05c0b7494ba8ddb50eb8.cloud_controller-20251112-064240-583066083.tgz
```


#### Step 1. Explode the logs 
[1_explode_bosh_logs.sh](1_explode_bosh_logs.sh) explodes bosh logs *.tgz file under ./tmp in current directory. it can takes bosh logs tgz file or path
```
./1_explode_bosh_logs.sh cf-05c0b7494ba8ddb50eb8.cloud_controller-20251112-064240-583066083.tgz
```
or

```
./1_explode_bosh_logs.sh .
```
it will explode the archive into ./tmp folder. 
re-running script will overwrite the same contents to the ./tmp folder.
```
ls -alh ./tmp   
drwxr-xr-x@  9 kminseok  staff   288B Nov 13 20:33 .
drwxr-xr-x@ 12 kminseok  staff   384B Nov 13 20:30 ..
drwxr-xr-x@ 15 kminseok  staff   480B Nov 12 15:50 cloud_controller.1ebd2b5c-b269-44cb-a06f-9ebf8b82f939.2025-11-12-06-50-27
drwxr-xr-x@ 15 kminseok  staff   480B Nov 12 15:50 cloud_controller.3956b231-0ec5-4dd9-9d76-c68a01604813.2025-11-12-06-50-30
```

#### Step 2. Analysis the bosh logs.
[2_analysis_logs.sh](2_analysis_logs.sh) will execute other subscripts at once and results the final output. optionally each scripts can be run separately. 


```
$ ./2_analysis_logs.sh

a_fetch_cf7_request_id_from_nginx_access_logs.sh
STARTING: gathering all entries from nginx-access.log ...
  making cache file for entries (timestamp, cf cli version, vcap_request_id) from nginx-access.log
COMPLETED: gathering all entries from nginx-access.log : total (   53991) ./tmp/output_a_fetch_cf7_request_id_from_nginx_access_logs.txt
Elapsed time: 2 seconds

b_fetch_users_from_security_events_logs.sh
STARTING: gathering all entries(timestamp, suser, suid, vcap_request_id) from security_events.log...
COMPLETED: gathering all entries from security_events.log:  (  129892) ./tmp/output_b_fetch_users_from_security_events_logs.txt
Elapsed time: 4 seconds

c_find_cf7_user.sh
STARTING: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log) ...
  total users input entries from ./tmp/output_b_fetch_users_from_security_events_logs.txt :   129892
  total cf cli input entries from  ./tmp/output_a_fetch_cf7_request_id_from_nginx_access_logs.txt :    53991
COMPLETED: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log): total (       4)  ./tmp/output_c_find_cf7_user.txt
```

analyzied result will be saved into ./tmp/output_c_find_cf7_user.txt. it shows username, user_guid and cf cli version.
```
[2025-11-12T03:59:59.276504 suser=appsadmin suid=f898a594-ddc8-4257-b9c7-b3b30338e800 cs2=2bce10c9-7985-4a0e-61c9-c569b1dff5a5::1cf0573d-256c-46b9-9f01-1411777db46d "cf7/7.7.14+c88114b.2024-09-20
[2025-11-12T03:24:36.343727 suser=admin suid=2328dd36-9e29-4835-822b-afaf39efdc37 cs2=a9b801ed-3f70-484c-541a-c089991d8048::c9bacc9a-9c0d-44a0-a2cf-eb0442bd7fa6 "cf/7.7.14+c88114b.2024-09-20
```

```
ls -alh ./tmp   
drwxr-xr-x@  9 kminseok  staff   288B Nov 13 20:33 .
drwxr-xr-x@ 12 kminseok  staff   384B Nov 13 20:30 ..
drwxr-xr-x@ 15 kminseok  staff   480B Nov 12 15:50 cloud_controller.1ebd2b5c-b269-44cb-a06f-9ebf8b82f939.2025-11-12-06-50-27
drwxr-xr-x@ 15 kminseok  staff   480B Nov 12 15:50 cloud_controller.3956b231-0ec5-4dd9-9d76-c68a01604813.2025-11-12-06-50-30
-rw-r--r--@  1 kminseok  staff   6.5M 11월 13 22:57 output_a_fetch_cf7_request_id_from_nginx_access_logs.txt
-rw-r--r--@  1 kminseok  staff    20M 11월 13 22:57 output_b_fetch_users_from_security_events_logs.txt
-rw-r--r--@  1 kminseok  staff   7.5K 11월 13 23:01 output_c_find_cf7_user_tmp.txt
-rw-r--r--@  1 kminseok  staff   346B 11월 13 22:57 output_c_find_cf7_user.txt
```

#### Step 3. (optional) Fetch user info

fetch additional user info using user_guid info gathered above.
```
 cf curl /v3/users/GUID| jq .
```

```
 cf curl /v3/users/f898a594-ddc8-4257-b9c7-b3b30338e800 | jq .

  "guid": "f898a594-ddc8-4257-b9c7-b3b30338e800",
  "created_at": "2025-04-16T08:10:58Z",
  "updated_at": "2025-04-16T08:10:58Z",
  "username": "appsadmin",
  "presentation_name": "appsadmin",
  "origin": "uaa",

```

## Detailed Explanation for each script.

#### [a_fetch_cf7_request_id_from_nginx_access_logs.sh](a_fetch_cf7_request_id_from_nginx_access_logs.sh)
From the nginx-access.log on the cloud controller VM logs, filter cf cli version and fetch vcap_request_id  by 'cf/7|cf7/7' string.

* a_fetch_cf7_request_id_from_nginx_access_logs.sh, b_fetch_users_from_security_events_logs.sh can be run in parallel as there is no dependency between them.

```
./a_fetch_cf7_request_id_from_nginx_access_logs.sh
STARTING: gathering all entries from nginx-access.log ...
  making cache file for entries (timestamp, cf cli version, vcap_request_id) from nginx-access.log
COMPLETED: gathering all entries from nginx-access.log : total (   53993) ./tmp/output_a_fetch_cf7_request_id_from_nginx_access_logs.txt
Elapsed time: 2 seconds
```

#### [b_fetch_users_from_security_events_logs.sh](b_fetch_users_from_security_events_logs.sh)

From the security_events.log, fetch user info by mapping the vcap_request_id. all entry from system user will be excluded from output file.

* a_fetch_cf7_request_id_from_nginx_access_logs.sh, b_fetch_users_from_security_events_logs.sh can be run in parallel as there is no dependency between them.

```
./b_fetch_users_from_security_events_logs.sh
STARTING: gathering all entries(timestamp, suser, suid, vcap_request_id) from security_events.log...
COMPLETED: gathering all entries from security_events.log:  (  129892) ./tmp/output_b_fetch_users_from_security_events_logs.txt
Elapsed time: 3 seconds
```

#### [c_find_cf7_user.sh](c_find_cf7_user.sh)
Mapping the vcap_request_id from security_events_log to cf cli version from nginx-access.log file on cloud controller vm logs.

```
$ ./c_find_cf7_user.sh

STARTING: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log) ...
  total users input entries from ./tmp/output_b_fetch_users_from_security_events_logs.txt :   129892
  total cf cli input entries from  ./tmp/output_a_fetch_cf7_request_id_from_nginx_access_logs.txt :    53991
COMPLETED: mapping from vcap_request_id(cc_security_events_log) to cf cli version(cc_nginx-access.log): total (       4)  ./tmp/output_c_find_cf7_user.txt
```

sample outputs shows username, user_guid and cf cli version.
```
$ cat ./tmp/output_c_find_cf7_user.txt

suser=admin suid=2328dd36-9e29-4835-822b-afaf39efdc37 "cf/7.7.14+c88114b.2024-09-20
suser=admin suid=2328dd36-9e29-4835-822b-afaf39efdc37 "cf7/7.7.14+c88114b.2024-09-20
suser=appsadmin suid=f898a594-ddc8-4257-b9c7-b3b30338e800 "cf/7.7.14+c88114b.2024-09-20
suser=appsadmin suid=f898a594-ddc8-4257-b9c7-b3b30338e800 "cf7/7.7.14+c88114b.2024-09-20
```

for more info with timestamp;
```
$ cat ./tmp/output_c_find_cf7_user_tmp.txt
...
suser=appsadmin suid=f898a594-ddc8-4257-b9c7-b3b30338e800 "cf7/7.7.14+c88114b.2024-09-20 [12/Nov/2025:03:55:25
suser=appsadmin suid=f898a594-ddc8-4257-b9c7-b3b30338e800 "cf7/7.7.14+c88114b.2024-09-20 [12/Nov/2025:03:59:58
suser=appsadmin suid=f898a594-ddc8-4257-b9c7-b3b30338e800 "cf7/7.7.14+c88114b.2024-09-20 [12/Nov/2025:03:59:59
...
```