# Platform log forwarding to multiple external syslog endpoint 
forwarding platform logs to additional syslog remotes using syslog-release is described in this [syslog-release document](https://github.com/cloudfoundry/syslog-release/blob/main/examples/example-custom-rules.md#forwarding-to-additional-remotes)
This document describe a solution how to achive above goal.

Tested on TAS 10.2.5, opsman 3.3

## How to apply

#### Opsman UI> TAS tile> System logging > Custom rsyslog configuration

add/replace keyword list in OR condition to forward 
> ```if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")```
> * contains_i directive ignores case
> * replace syslog remote IP/PORT.
> * StreamDriverMode: "0" for non tls
> * Template: default from tanzu.


if `Do not forward debug logs` option checked, then add additional filter to prevent forwarding DEBUG logs. this is because if the option checked, then `if ($msg contains "DEBUG") then stop` filter is added AFTER additnal remote endpoint by platform.
> ```if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] and not($msg contains ["DEBUG"]) then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")```

also add filter to prevent `vcap.agent` logs.
> ```if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] and not($msg contains ["DEBUG"]) and not ($programname startswith "vcap.")  then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")``` 

refer to the rainer script document https://www.rsyslog.com/doc/configuration/filters.html


apply change TAS tile.


### BOSH tile

it is also applicable to bosh tile as well.
> ```if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] and not($msg contains ["DEBUG", "director_api", "audisp", "auditd" ]) and not ($programname startswith "vcap.")  then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")```
> * added more keyword to prevent forwaring logs. such as director_api, audisp-syslog, auditd



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

if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] and not($msg contains ["DEBUG"]) and not ($programname startswith "vcap.")  then action(type="omfwd" protocol="tcp" queue.type="linkedList" Target="192.168.0.6"  Port="514"  StreamDriverMode="0" Template="SyslogForwarderTemplate")

if ($programname startswith "vcap.") then stop
if ($msg contains "DEBUG") then stop
```


## TLS syslog endpoint


if default system logging is not configured with TLS or TLS CA cert configured on the default system logging on tiles is not compatible with additonal syslog endpoint, then there is no available CA file on the deployed VMs.

In this scenario, following steps can inject cert. it applies both BOSH, TAS tile and other tiles.(and verified on bosh, TAS)

1. add your additional syslog endpoint CA cert on BOSh tile > Security > Trusted Certificates
=> it will be uploaded to "/etc/ssl/certs/ca-certificates.crt" on each deployed VM.

2. configure additional endpoints with following Custom rsyslog configuration:
> ```if $msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] and not($msg contains ["DEBUG"]) and not ($programname startswith "vcap.")  then action(type="omfwd" protocol="tcp" queue.type="linkedList"  Template="SyslogForwarderTemplate" Target="logs.example.com"  Port="514"   StreamDriver="gtls"  StreamDriverMode="1" StreamDriverAuthMode="x509/name"  StreamDriverPermittedPeers="logs.example.com" streamDriver.CAFile="/etc/ssl/certs/ca-certificates.crt" )```
> * make sure the streamDriver.CAFile property that has dot on it's name.
> * target and StreamDriverPermittedPeers property value should be matched
> * CA file location of the default syslog endpoint is /var/vcap/jobs/syslog_forwarder/config/ca_cert.pem 


## Filtered logs

### event:  cf login ( capture user=)

#### from default syslog endpoint:
```
2026-01-20T04:56:26.360194Z 192.168.0.61 uaa[rs2] [2026-01-20T04:56:26.322731Z] uaa - 11 [https-jsse-nio-8443-exec-9] - [eebfc71902a0476ead3b365dc8a091b4,c3f14c02ca9d1c91] ....  INFO --- Audit: TokenIssuedEvent ('["openid","scim.read","cloud_controller.admin","uaa.user","cloud_controller.read","password.write","cloud_controller.write","scim.write"]'): principal=35bebebf-e599-4204-90be-f99561ffeb93, origin=[client=cf, user=appsadmin], identityZoneId=[uaa]
2026-01-20T04:56:26.377302Z 192.168.0.61 uaa[rs2] [2026-01-20T04:56:26.322731Z] uaa - 11 [https-jsse-nio-8443-exec-9] - [eebfc71902a0476ead3b365dc8a091b4,c3f14c02ca9d1c91] ....  INFO --- Audit: TokenIssuedEvent ('["openid","scim.read","cloud_controller.admin","uaa.user","cloud_controller.read","password.write","cloud_controller.write","scim.write"]'): principal=35bebebf-e599-4204-90be-f99561ffeb93, origin=[client=cf, user=appsadmin], identityZoneId=[uaa]
2026-01-20T04:56:27.355952Z 192.168.0.62 cloud_controller_ng[rs2] I, [2026-01-20T04:56:26.384189 #19]  INFO -- : CEF:0|cloud_foundry|cloud_controller_ng|2.268.0|GET /v3/organizations|GET /v3/organizations|0|rt=1768884986384 suser=appsadmin suid=35bebebf-e599-4204-90be-f99561ffeb93 request=/v3/organizations?order_by\=name requestMethod=GET src=192.168.0.217 dst=192.168.0.62 cs1Label=userAuthenticationMechanism cs1=oauth-access-token cs2Label=vcapRequestId cs2=eebfc719-02a0-476e-ad3b-365dc8a091b4::8fa33438-3f10-46b9-a7fc-851bf2441ac0 cs3Label=result cs3=success cs4Label=httpStatusCode cs4=200 cs5Label=xForwardedFor cs5=192.168.0.217, 192.168.0.70
```


#### from additional remote syslog endpoint:
it receives subset of logs from default endpoints.
```
Jan 20 04:56:26 192.168.0.61 uaa[rs2] [2026-01-20T04:56:26.322731Z] uaa - 11 [https-jsse-nio-8443-exec-9] - [eebfc71902a0476ead3b365dc8a091b4,c3f14c02ca9d1c91] ....  INFO --- Audit: TokenIssuedEvent ('["openid","scim.read","cloud_controller.admin","uaa.user","cloud_controller.read","password.write","cloud_controller.write","scim.write"]'): principal=35bebebf-e599-4204-90be-f99561ffeb93, origin=[client=cf, user=appsadmin], identityZoneId=[uaa]
Jan 20 04:56:26 192.168.0.61 uaa[rs2] [2026-01-20T04:56:26.322731Z] uaa - 11 [https-jsse-nio-8443-exec-9] - [eebfc71902a0476ead3b365dc8a091b4,c3f14c02ca9d1c91] ....  INFO --- Audit: TokenIssuedEvent ('["openid","scim.read","cloud_controller.admin","uaa.user","cloud_controller.read","password.write","cloud_controller.write","scim.write"]'): principal=35bebebf-e599-4204-90be-f99561ffeb93, origin=[client=cf, user=appsadmin], identityZoneId=[uaa]
Jan 20 04:56:27 192.168.0.62 cloud_controller_ng[rs2] I, [2026-01-20T04:56:26.384189 #19]  INFO -- : CEF:0|cloud_foundry|cloud_controller_ng|2.268.0|GET /v3/organizations|GET /v3/organizations|0|rt=1768884986384 suser=appsadmin suid=35bebebf-e599-4204-90be-f99561ffeb93 request=/v3/organizations?order_by\=name requestMethod=GET src=192.168.0.217 dst=192.168.0.62 cs1Label=userAuthenticationMechanism cs1=oauth-access-token cs2Label=vcapRequestId cs2=eebfc719-02a0-476e-ad3b-365dc8a091b4::8fa33438-3f10-46b9-a7fc-851bf2441ac0 cs3Label=result cs3=success cs4Label=httpStatusCode cs4=200 cs5Label=xForwardedFor cs5=192.168.0.217, 192.168.0.70
```
### event:  DEBUG level logs
#### from default syslog endpoint:
no logs due to "DEBUG" filter.


#### from additional remote syslog endpoint:
no logs due to "DEBUG" filter.



