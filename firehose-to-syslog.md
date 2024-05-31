
# cloud foundry의 loggregator에서 수집한 메트릭, 이벤트, 로그를 외부로 전송하기
cloud foundry의 loggregator에서 수집한 메트릭, 이벤트, 로그는 firehose를 통해 제공됩니다.(https://docs.pivotal.io/pivotalcf/2-3/loggregator/architecture.html)  아래와 같은 nozzle을 연결하면 데이터를 추출할 수 있습니다.

1) The Datadog nozzle, which publishes metrics coming from the Firehose to Datadog: https://github.com/cloudfoundry-incubator/datadog-firehose-nozzle
2) Syslog nozzle, which filters out log messages coming from the Firehose and sends it to a syslog server: https://github.com/cloudfoundry-community/firehose-to-syslog
nozzle을 구현하여 수집할 수 있으며 여기서는 두가지 방법으로 수집하는 방법을 설명합니다.

## PCF Key Performance Indicator

https://docs.pivotal.io/pivotalcf/2-3/monitoring/kpi.html#cell


## cf nozzle plugin

https://docs.cloudfoundry.org/loggregator/cli-plugin.html#add
```
$ cf add-plugin-repo CF-Community https://plugins.cloudfoundry.org
$ cf install-plugin -r CF-Community "Firehose Plugin"
$ cf nozzle

What type of firehose messages do you want to see?

Please enter one of the following choices:
	  hit 'enter' for all messages
	  4 for HttpStartStop
	  5 for LogMessage
	  6 for ValueMetric
	  7 for CounterEvent
	  8 for Error
	  9 for ContainerMetric
	> 6
Starting the nozzle
Hit Ctrl+c to exit
origin:"garden-linux" eventType:ValueMetric timestamp:1542179043567772223 deployment:"cf" job:"diego_cell" index:"49c828db-8e3e-4900-88bd-3cb0df62aac3" ip:"10.10.12.35" tags:<key:"source_id" value:"garden-linux" > valueMetric:<name:"memoryStats.numBytesAllocatedStack" value:1.1337728e+07 unit:"count" >  

origin:"garden-linux" eventType:ValueMetric timestamp:1542179043567849619 deployment:"cf" job:"diego_cell" index:"49c828db-8e3e-4900-88bd-3cb0df62aac3" ip:"10.10.12.35" tags:<key:"source_id" value:"garden-linux" > valueMetric:<name:"memoryStats.numFrees" value:3.6428645e+07 unit:"count" >  
```


## firehose-to-syslog app
PAS에 firehose-to-syslog app을 배포해서 loggregator의 수집내용을 외부의 syslog서버로 보냅니다.
https://github.com/cloudfoundry-community/firehose-to-syslog

#### syslog 서버 준비
VM을 생성하고 rsyslog서버를 실행합니다. syslog서버는 udp, tcp, 514포트로 준비합니다.
참고 ubuntu기준 http://yallalabs.com/linux/how-to-setup-a-centralized-log-server-using-rsyslog-on-ubuntu-16-04-lts/
```
[root@logserver ~]# vi /etc/rsyslog.d/tmpl.conf

$template TmplAuth, "/var/log/client_logs/%HOSTNAME%/%PROGRAMNAME%.log"
$template TmplMsg, "/var/log/client_logs/%HOSTNAME%/%PROGRAMNAME%.log"

authpriv.* ?TmplAuth
*.info;mail.none;authpriv.none;cron.none ?TmplMsg


[root@logserver ~]# sudo ufw allow 514/tcp
[root@logserver ~]# sudo ufw allow 514/udp


[root@logserver ~]# sudo ufw reload
[root@logserver ~]# systemctl restart rsyslog

[root@server01 ~]# systemctl restart rsyslog

logger -s " This is my Rsyslog client "
```

#### push app
https://github.com/cloudfoundry-community/firehose-to-syslog
``` git clone https://github.com/cloudfoundry-community/firehose-to-syslog
cd firehose-to-syslog
```

vi manifest.yml
```
applications:
- name: firehose-to-syslog
  health-check-type: process
  env:
    GOPACKAGENAME: github.com/cloudfoundry-community/firehose-to-syslog
    API_ENDPOINT: https://api.[your cf system domain]
    DEBUG: false 
    DOPPLER_ENDPOINT: wss://doppler.[your cf system domain]:443
    EVENTS: LogMessage,ValueMetric,Error,ContainerMetric
    FIREHOSE_CLIENT_ID: <your  healthwatch_firehose client>     
    FIREHOSE_CLIENT_SECRET: <your  healthwatch_firehose secret> 
    FIREHOSE_SUBSCRIPTION_ID: firehose-to-syslog 
    LOG_EVENT_TOTALS: true
    LOG_EVENT_TOTALS_TIME: 10s
    SKIP_SSL_VALIDATION: true
    SYSLOG_ENDPOINT: <your syslog server IP>:514
    SYSLOG_PROTOCOL: udp  # tcp/udp/tcp+tls
    CERT_PEM: ./log_cache_nozzle_client_tls_cert.pem 

=== 파라미터 가이드===
FIREHOSE_CLIENT_ID:  opsmanager> PAS> credentials> Healthwatch Firehose Credentials>id
FIREHOSE_CLIENT_SECRET: opsmanager> PAS> credentials> Healthwatch Firehose Credentials> secret
CERT_PEM: opsmanager> PAS> credentials>log_cache_nozzle_client_tls_cert > private_key_pem의 내용을 별도 파일로 작성후, chmod 600 ./log_cache_nozzle_client_tls_cert.pem 

   -----BEGIN RSA PRIVATE KEY-----
   xxx
   -----END RSA PRIVATE KEY-----
   
SYSLOG_ENDPOINT: 외부에 준비된 syslog 서버 IP
SYSLOG_PROTOCOL: tcp/udp/tcp+tls
```
   
sample.
```
applications:
- name: firehose-to-syslog
  health-check-type: process
  env:
    GOPACKAGENAME: github.com/cloudfoundry-community/firehose-to-syslog
    API_ENDPOINT: http://api.sys.ds.lab
    DEBUG: true
    DOPPLER_ENDPOINT: wss://doppler.sys.ds.lab:443
    EVENTS: LogMessage,ValueMetric,Error,ContainerMetric
    FIREHOSE_CLIENT_ID: metricbeat
    FIREHOSE_CLIENT_SECRET: xxxx
    FIREHOSE_SUBSCRIPTION_ID: firehose-to-syslog-app
    LOG_EVENT_TOTALS: true
    LOG_EVENT_TOTALS_TIME: 10s
    SKIP_SSL_VALIDATION: true
    SYSLOG_ENDPOINT: 10.1.4.8:514
    SYSLOG_PROTOCOL: tcp  # tcp/udp/tcp+tls
```

```
cf login -a https://api.[your cf system domain] -u [your id] --skip-ssl-validation
cf push firehose-to-syslog --no-route
cf logs firehose-to-syslog  => 에러없이 아래의 로그가 나오면 syslog로 전송중임 ...
   2018-11-14T15:50:37.31+0900 [APP/PROC/WEB/0] OUT [2018-11-14 06:50:37.310510943 +0000 UTC] Starting firehose-to-syslog 0.0.0 
   2018-11-14T15:50:37.36+0900 [APP/PROC/WEB/0] OUT wss://doppler.system.pcfdemo.net:443
   2018-11-14T15:50:37.36+0900 [APP/PROC/WEB/0] OUT [2018-11-14 06:50:37.363231231 +0000 UTC] Using wss://doppler.system.xxx.net:443 as doppler endpoint
   2018-11-14T15:50:37.36+0900 [APP/PROC/WEB/0] OUT [2018-11-14 06:50:37.363370864 +0000 UTC] Pre-filling cache...
   2018-11-14T15:50:39.06+0900 [APP/PROC/WEB/0] OUT [2018-11-14 06:50:39.069227298 +0000 UTC] Cache filled.
   2018-11-14T15:50:39.06+0900 [APP/PROC/WEB/0] OUT [2018-11-14 06:50:39.069556675 +0000 UTC] Connected to Syslog Server! Connecting to Firehose.
   
```

### PCF KPI 확인
https://docs.pivotal.io/pivotalcf/2-3/monitoring/kpi.html#cell
```
Remaining Memory Available — Cell Memory Chunks Available: rep.CapacityRemainingMemory
```

```
$ cd /var/log/
$ tail -f syslog | grep CapacityRemainingMemory
Nov 14 16:23:44 10.10.12.51  2018-11-14T07:23:44Z c5cdf522-0ea3-4658-5932-b56b doppler[17]: {"cf_origin":"firehose","deployment":"cf","event_type":"ValueMetric","ip":"10.10.12.51","job":"diego_cell","job_index":"ed084dc3-12d2-4036-b690-875233e11b07","level":"info","msg":"","name":"CapacityRemainingMemory","origin":"rep","time":"2018-11-14T07:23:44Z","unit":"MiB","value":10152}
Nov 14 16:23:45 10.10.12.51  2018-11-14T07:23:45Z c5cdf522-0ea3-4658-5932-b56b doppler[17]: {"cf_origin":"firehose","deployment":"cf","event_type":"ValueMetric","ip":"10.10.12.37","job":"diego_cell","job_index":"4c976cec-a48b-4c91-be38-77f697e415ce","level":"info","msg":"","name":"CapacityRemainingMemory","origin":"rep","time":"2018-11-14T07:23:45Z","unit":"MiB","value":5172}

```
### Rsyslog filter (ubuntu)
rsyslog filter in  /etc/rsyslog.conf will filter unuseful logs.
```
#################
#### MODULES ####
#################

$ModLoad imuxsock # provides support for local system logging
$ModLoad omrelp
#$ModLoad immark  # provides --MARK-- message capability

# provides UDP syslog reception
#$ModLoad imudp
#$UDPServerRun 514

# provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

...


# Include all config files in /etc/rsyslog.d/
## add this before #IncludeConfig.
## remove this after testing to prevent any further unwanted filtering.
:msg, contains, "DEBUG" stop
:msg, contains, "INFO" stop
#:msg, regex, "HTTP/1.* 200" stop
#:msg, regex, "HTTP/1.* 206" stop


$IncludeConfig /etc/rsyslog.d/*.conf

```

then 
```
service rsyslog restart
service rsyslog status
```
#### Generating logs with sample apps
https://github.com/myminseok/hello-python-logs
