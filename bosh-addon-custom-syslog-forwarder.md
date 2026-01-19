# Platform log forwarding to multiple external syslog endpoint 
forwarding platform logs to additional syslog remotes using syslog-release is described in this [syslog-release document](https://github.com/cloudfoundry/syslog-release/blob/main/examples/example-custom-rules.md#forwarding-to-additional-remotes)
This document describe a solution how to achive above goal.

## How to apply

#### Opsman UI> TAS tile> System logging > Custom rsyslog configuration

```
if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")
```
>> add/replace keyword list to filter logs to forward (OR condition)
>> replace syslog remote IP/PORT.
>> StreamDriverMode: "0" for non tls
>> Template: default from tanzu.


apply change TAS tile.

#### Changes on target VM

```
nats/0fb2b265-81e4-4790-b466-e80bc81eb4d0:/etc/rsyslog.d#ls -al /etc/rsyslog.d
total 44
drwxr-xr-x  2 root root 4096 Jan 19 02:31 ./
drwxr-xr-x 86 root root 4096 Jan 19 01:47 ../
-rw-r--r--  1 root root 1559 Dec 19 03:49 20-syslog-release.conf
-rw-r--r--  1 root root 1731 Jan 19 01:26 25-syslog-release-forwarding-setup.conf
-rw-r--r--  1 root root   86 Jan 19 02:28 30-syslog-release-custom-rules.conf
-rw-r--r--  1 root root    1 Dec 19 03:49 32-syslog-release-vcap-filter.conf
-rw-r--r--  1 root root    1 Dec 19 03:49 33-syslog-release-debug-filter.conf
-rw-r--r--  1 root root   73 Jan 19 02:31 35-syslog-release-forwarding-rules.conf
-rw-r--r--  1 root root  263 Dec 19 03:49 40-syslog-release-file-exclusion.conf
-rw-r--r--  1 root root 1864 Nov  1 12:30 50-default.conf
```

```
nats/0fb2b265-81e4-4790-b466-e80bc81eb4d0:/etc/rsyslog.d# cat ./30-syslog-release-custom-rules.conf

if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")
if ($programname startswith "vcap.") then stop
if ($msg contains "DEBUG") then stop
```