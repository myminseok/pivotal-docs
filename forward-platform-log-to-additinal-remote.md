# Platform log forwarding to multiple external syslog endpoint 
forwarding platform logs to additional syslog remotes using syslog-release is described in this [syslog-release document](https://github.com/cloudfoundry/syslog-release/blob/main/examples/example-custom-rules.md#forwarding-to-additional-remotes)
This document describe a solution how to achive above goal.

Tested on TAS 10.2.5

## How to apply

#### Opsman UI> TAS tile> System logging > Custom rsyslog configuration

```
if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")
```
>> add/replace keyword list to filter logs to forward (OR condition), contains_i directive ignores case
>> replace syslog remote IP/PORT.
>> StreamDriverMode: "0" for non tls
>> Template: default from tanzu.


if `Do not forward debug logs` option checked, then add following additional filter to prevent forwarding DEBUG logs.
this is to apply the same filter as the default syslog endpoint.
```
if not($msg contains ["DEBUG"]) and  $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")
```
or
```
if ($msg contains "DEBUG") then stop
if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")
``` 

apply change TAS tile.

#### Changes on target VM

the configuration is injected into `30-syslog-release-custom-rules.conf` file.

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

if not($msg contains ["DEBUG"]) and $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")
if ($programname startswith "vcap.") then stop
if ($msg contains "DEBUG") then stop
```

## Filtered logs

### event:  cf login ( capture user=)

#### from default syslog endpoint:

Jan 19 03:08:39 192.168.0.61 uaa/uaa_events.log[rs2] [2026-01-19T03:08:39.196598Z] uaa - 11 [https-jsse-nio-8443-exec-1] - [3d95f0272bdf45d28de864b4a895b1d9,af628c6f046fb443] ....  INFO --- Audit: TokenIssuedEvent ('["openid","scim.read","cloud_controller.admin","uaa.user","cloud_controller.read","password.write","cloud_controller.write","scim.write"]'): principal=35bebebf-e599-4204-90be-f99561ffeb93, origin=[client=cf, user=appsadmin], identityZoneId=[uaa]

#### from additional remote syslog endpoint:
the same as default syslog endpoint


### event:  DEBUG level logs
#### from default syslog endpoint:
no logs due to "DEBUG" filter.


#### from additional remote syslog endpoint:
no logs due to "DEBUG" filter.