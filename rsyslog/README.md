this guide describes how to forward syslog from bosh deployed VM to remote rsyslog server.

syslog includes
- /var/vcap/sys/log/*
- /var/log/*

  
## Configure rsyslog server on opsmanager VM.

edit /etc/[rsyslog.conf](rsyslog.conf)

```
...
# provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

...


$template SysLogName,"/var/log/rsyslog-tas/%fromhost-ip%_syslog_%$YEAR%-%$MONTH%-%$DAY%.log"
*.*;auth,authpriv.none ?SysLogName
$template KernLogName,"/var/log/rsyslog-tas/%fromhost-ip%_kernlog_%$YEAR%-%$MONTH%-%$DAY%.log"
kern.* ?KernLogName
#
# Include all config files in /etc/rsyslog.d/
#
$IncludeConfig /etc/rsyslog.d/*.conf
```
above config will not log `auth.log`, but syslog already includes auth log in it.
```
service rsyslog restart
```

then, /var/log/rsyslog-tas will be created.



## Configure system logging on a tile( such as isolation segment) from ops manager.
```
tile > system logging
Syslog server address : rsyslog server IP
Syslog server port: 514
Transport Protocol: UDP
Send logs over TLS: uncheck
Use TCP for file forwarding local transport: uncheck
Do not forward debug logs: check
```
refer to https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-platform-for-cloud-foundry/10-0/tpcf/config-sys-logs.html

and apply change

test the syslog forwarding via `logger` from the bosh deployed vm for the tile.

```
Deployment 'p-isolation-segment-is1-be88884da92c4fec9b8f'

Instance                                                      Process State  AZ              IPs           VM CID                                                                           VM Type     Active  Stemcell
isolated_diego_cell_is1/e214b1c5-f286-4a6a-84e5-75ff27dcc6a0  running        tas-hostgroup1  192.168.0.76  isolated-diego-cell-is1_p-isolation-segment-is1-be88884da92c4fec9b_5fcc51c78923  large.disk  true    bosh-vsphere-esxi-ubuntu-jammy-go_agent/1.621
isolated_router_is1/e6c41f1b-5d3f-4ca9-a7ea-3fbf1d7ac41b      running        tas-hostgroup1  192.168.0.90  isolated-router-is1_p-isolation-segment-is1-be88884da92c4fec9b8f_603afe9822b8    micro       true    bosh-vsphere-esxi-ubuntu-jammy-go_agent/1.621

ubuntu@opsmanager-3-0$ bosh -d p-isolation-segment-is1-be88884da92c4fec9b8f ssh isolated_router_is1/0

isolated_router_is1/e6c41f1b-5d3f-4ca9-a7ea-3fbf1d7ac41b:~$ logger test
```

then the test message should be logged in opsmanager from file named after IP of rsyslog client VM.
```
ubuntu@opsmanager-3-0# tail -f /var/log/rsyslog-tas/192.168.0.90_syslog_2024-12-03.log
...
2024-12-03T08:17:11.572057+00:00 192.168.0.90 bosh_44f1299caa3a48e test
```


## setup logrotate config

create [/etc/logrotate.d/logrotate-tas](logrotate-tas) configuration

note that size is 5K for testing purpose
```
root@opsmanager-3-0:/etc/logrotate.d# cat logrotate-tas
/var/log/rsyslog-tas/*.log
{
	su syslog syslog
  daily
	rotate 5
	nodateext
	size 5K
	missingok
	notifempty
	delaycompress
	compress
}
```

```
service logrotate restart
```
as soon as restart logrotate service, file will be rotated.
```
drwxrwxr-x 13 root   syslog   4096 Dec  3 08:08 ../
-rw-r-----  1 syslog syslog  23073 Dec  3 08:21 127.0.0.1_syslog_2024-12-03.log
-rw-r-----  1 syslog syslog 146843 Dec  3 08:21 127.0.0.1_syslog_2024-12-03.log.1
-rw-r-----  1 syslog syslog      0 Dec  3 08:21 192.168.0.90_syslog_2024-12-03.log
-rw-r-----  1 syslog syslog 214600 Dec  3 08:21 192.168.0.90_syslog_2024-12-03.log.1
```

update size to 5M and restart logroteate service. 
```
/var/log/rsyslog-tas/*.log
{
	su syslog syslog
        daily
	rotate 5
	nodateext
	size 5M
...
```
service logrotate restart
