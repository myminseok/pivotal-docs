
# A guide to early parsing/indexing syslog from PCF
 PAS annotates forwarded messages with structured data. This structured data identifies the originating BOSH Director, deployment, instance group, availability zone, and instance ID. this guild will show you how to form logstash.conf. refer to  https://docs.pivotal.io/pivotalcf/2-4/customizing/custom-syslog-rules.html for more detail.
 

## purpose
this docs shows how to form logstash parsing rule using rsyslogd server temporillay. Infact, you can directly forward syslog from PAS to logstash in production. but some situation, it can be useful such as:
- you cannot access logstash env of the target ELK.
- early filtering or indexing for more efficient log handling.


### structured syslog data from PAS
```
<$PRI>$VERSION $TIMESTAMP $HOST $APP_NAME $PROC_ID $MSG_ID   
    [instance@ENTERPRISE_NUMBER director="$DIRECTOR" deployment="$DEPLOYMENT" 
    group="$INSTANCE_GROUP" az="$AVAILABILITY_ZONE" id="$ID"] $MESSAGE
```


## setup remote rsyslogd server

/etc/rsyslog.conf

```
# provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

###########################
#### GLOBAL DIRECTIVES ####
###########################

#
# Use traditional timestamp format.
# To enable high precision timestamps, comment out the following line.
#
#$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
#$ActionFileDefaultTemplate RSYSLOG_FileFormat
#$ActionFileDefaultTemplate RSYSLOG_DebugFormat

$template pcf_format,"%rawmsg%\n"
$ActionFileDefaultTemplate pcf_format


$FileCreateMode 0644


if ($rawmsg contains 'deployment=') then
{
  /var/log/pcf-tile.log;pcf_format
}
else if ( $rawmsg contains 'component":"Ops Manager') then
{
  /var/log/pcf-opsman.log
}
else{
  /var/log/syslog
}

#
# Include all config files in /etc/rsyslog.d/
#
$IncludeConfig /etc/rsyslog.d/*.conf

```

comment out other duplicated log file in /etc/rsyslog.d/50-default.conf
```
# First some standard log files.  Log by facility.
#
auth,authpriv.*			/var/log/auth.log
#*.*;auth,authpriv.none		-/var/log/syslog
#user.*				-/var/log/user.log


#daemon.*;mail.*;\
	news.err;\
	*.=debug;*.=info;\
	*.=notice;*.=warn	|/dev/xconsole
  

```

```
$ sudo service rsyslog restart

$ ls -al /var/log/ 
drwxrwxrwx  2 root   root           4096 Aug 29 03:51 opsmanager
-rw-r--r--  1 syslog syslog    270113934 Aug 29 04:36 pcf-opsman.log
-rw-r--r--  1 syslog syslog    340348541 Aug 29 06:31 pcf-tile.log
```


```
$ tail -f /var/log/pcf-tile.log

<14>1 2019-08-29T03:06:50.872803Z 172.16.0.20 director rs2 - [instance@47450 director="" deployment="p-bosh" group="" az="unknown" id="5e7b2114-2cc3-4d12-5b16-f706701e3e81"] I, [2019-08-29T03:06:50.339906 #29] []  INFO -- DirectorAudit: {"id":16229,"parent_id":null,"user":"health_monitor","timestamp":"2019-08-29 03:06:50 UTC","action":"create","object_type":"alert","object_name":"1567048010.1340542201@localhost","error":null,"task":null,"deployment":"service-instance_157b3f9e-f631-42ae-8d5b-88aa9e3ee2ec","instance":"mysql/f04fa7ed-a6d5-4ec4-a4dc-cc87cec43158","context_json":"{\"message\":\"mysql-agent (10.0.4.34) - Does not exist - restart. Alert @ 2019-08-29 03:06:50 UTC, severity 1: process is not running\"}”}

<14>1 2019-08-29T02:35:30.77332Z 10.0.4.136 rep rs2 - [instance@47450 director="" deployment="cf-38126f33d43fd27736c2" group="diego_cell" az="kr-pub-b" id="1100e98a-ad5d-4c73-8cc3-7a5695f1b635"] {"timestamp":"2019-08-29T02:35:30.059231288Z","level":"info","source":"rep","message":"rep.container-metrics-reporter.tick.get-all-metrics.containerstore-metrics.starting","data":{"session":"9.441.1.1”}}

<7>1 2019-08-29T03:11:50.446781+00:00 10.0.4.33 vcap.agent 12458 - [instance@47450 director="172.16.0.20" deployment="pivotal-mysql-2d4ddb42e9b97f5c9164" group="dedicated-mysql-broker" az="kr-pub-b" id="d64fd817-af6a-48b2-8b4c-3e0be476b062"] 2019/08/29 03:11:50 CEF:0|CloudFoundry|BOSH|1|agent_api|get_task|1|duser=director.088dc4d2-4166-4254-b628-f2abddf3bde2.f03eedc1-638a-4845-a925-bec46b6a37d9.29dd5b8f-572a-4443-8009-90652231ce88 src=172.16.0.20 spt=4222 shost=f03eedc1-638a-4845-a925-bec46b6a37d9

<7>1 2019-08-29T03:13:42.509739+00:00 q-m84n2s0.q-g257.bosh vcap.agent 17077 - [instance@47450 director="172.16.0.20" deployment="service-instance_157b3f9e-f631-42ae-8d5b-88aa9e3ee2ec" group="mysql" az="kr-pub-b" id="f04fa7ed-a6d5-4ec4-a4dc-cc87cec43158"] 2019/08/29 03:13:42 CEF:0|CloudFoundry|BOSH|1|agent_api|get_task|1|duser=director.088dc4d2-4166-4254-b628-f2abddf3bde2.0d935d12-0383-4799-98b0-2766ba4a2445.28876eb2-ab4e-4f56-9f9c-7144ae66bd61 src=172.16.0.20 spt=4222 shost=0d935d12-0383-4799-98b0-2766ba4a2445


```

## lets parse /var/log/pcf-tile.log for forwarding to logstash.

```
$ wget http://download.elastic.co/logstash/logstash/logstash-1.5.6.tar.gz
$ tar xf logstash-1.5.6.tar.gz
$ cd logstash-1.5.6

$ ubuntu@opsman-jumpbox:~/logstash-1.5.6$ vi logstash.conf

input {
  file {
    path =>  [ "/var/log/pcf-tile.log" ]
    type => "pcf-tile-log"
  }
}

filter{
 if [type] == "pcf-tile-log"{
  grok{
    match  => {
      "message" => "(<%{NUMBER}>)? %{TIMESTAMP_ISO8601:timestamp}% %{IPORHOST:host} %{USERNAME:app_name} (%{WORD:proc_id})?(%{SPACE}-).* \[(%{WORD}@%{WORD})? (director=\"(%{IPORHOST:director})?)?\" deployment=\"(%{USERNAME:deployment})?\" (%{GREEDYDATA:msg})?"
    } #match
  add_tag => [ "valid" ]
  }# grok
 } #if

 if [msg] =~ "\"level\":\"debug\"" or [msg] =~ "\"level\":\"info\"" or [msg] =~ "\"level\":\"warn\"" or
    [msg] =~ "HTTP.* 20[0-9]" or
    [msg] =~ "DEBUG" or  [msg] =~ "INFO" {
      mutate {
        add_field => { "logLevel" => "DEBUG" }
      }
  }else if [msg] =~ "\"level\":\"error\"" or [msg] =~ "ERROR" {
      mutate {
        add_field => { "logLevel" => "ERROR" }
	add_field => { "errorType" => "errorType" }
      }
  }else if  [msg] =~ "Failed" {
      mutate {
        add_field => { "logLevel" => "ERROR" }
	add_field => { "errorType" => "failed" }
      }
  }else if [msg] =~ "Unauthorized" {
      mutate {
        add_field => { "logLevel" => "ERROR" }
	add_field => { "errorType" => "auth" }
      }
  }else if [msg] =~ "HTTP.* 40[0-9]" or [msg] =~ "HTTP.* 50[0-9]" {
      mutate {
        add_field => { "logLevel" => "ERROR" }
	add_field => { "errorType" => "http" }
      }
  } else {
      mutate {
        add_field => { "logLevel" => "DEBUG" }
      }
  }
  
 if "valid" not in [tags] or "DEBUG" in [logLevel] {
    drop { }
 }

 mutate {
    remove_tag => [ "valid" ]
    remove_field => [ "@version", "@timestamp", "path", "tag", "message" ]
 }

} # filter

output{
 # only for debug.
 stdout { codec => rubydebug }
}
```
please note that PAS provides a empty `director` field. you may set this value manually in opsman UI> PAS tile> settings> System Logging > Custom rsyslog Configuration as following value and apply change. it will override the original setting.
```
reset $.director = "<any-foundation-name>";
```
donot forget trailing ';'.

## run test logstash.
```

$ ubuntu@opsman-jumpbox:~/logstash-1.5.6$ ./bin/logstash -f ./logstash.conf  --debug --verbose

       "message" => [
        [0] "<14>1 2019-08-29T06:22:22.397375Z 10.0.4.18 cloud_controller_ng rs2 - [instance@47450 director=\"\" deployment=\"cf-38126f33d43fd27736c2\" group=\"cloud_controller\" az=\"kr-pub-a\" id=\"c7c1428b-7aea-4945-a243-b05653d820b0\"] 10.0.4.18 - [29/Aug/2019:06:22:21 +0000] \"GET /v2/info HTTP/1.1\" 200 969 \"-\" \"monit/5.2.5\" 10.0.4.18 vcap_request_id:557a4fe5-137a-4469-8817-37a07776c81d response_time:0.004",
        [1] "group=\"cloud_controller\" az=\"kr-pub-a\" id=\"c7c1428b-7aea-4945-a243-b05653d820b0\"] 10.0.4.18 - [29/Aug/2019:06:22:21 +0000] \"GET /v2/info HTTP/1.1\" 200 969 \"-\" \"monit/5.2.5\" 10.0.4.18 vcap_request_id:557a4fe5-137a-4469-8817-37a07776c81d response_time:0.004"
    ],
      "@version" => "1",
    "@timestamp" => "2019-08-29T06:38:19.033Z",
          "host" => [
        [0] "0.0.0.0",
        [1] "10.0.4.18"
    ],
          "path" => "/var/log/pcf.log",
          "type" => "pcf-log",
     "timestamp" => "2019-08-29T06:22:22.397375Z",
      "app_name" => "cloud_controller_ng",
       "proc_id" => "rs2",
       "director" => "",
    "deployment" => "cf-38126f33d43fd27736c2",
          "tags" => []
          
          
          {
       "message" => [
        [0] "<14>1 2019-08-29T06:22:21.523509Z q-m84n2s0.q-g257.bosh mysql-metrics rs2 - [instance@47450 director=\"172.16.0.20\" deployment=\"service-instance_157b3f9e-f631-42ae-8d5b-88aa9e3ee2ec\" group=\"mysql\" az=\"kr-pub-b\" id=\"f04fa7ed-a6d5-4ec4-a4dc-cc87cec43158\"] {\"timestamp\":\"1567059740.941682100\",\"source\":\"MetricsLogger\",\"message\":\"MetricsLogger.Emitted metric\",\"log_level\":0,\"data\":{\"metric\":{\"key\":\"follower/is_follower\",\"value\":0,\"unit\":\"boolean\",\"RawValue\":\"\",\"Error\":null}}}",
        [1] "group=\"mysql\" az=\"kr-pub-b\" id=\"f04fa7ed-a6d5-4ec4-a4dc-cc87cec43158\"] {\"timestamp\":\"1567059740.941682100\",\"source\":\"MetricsLogger\",\"message\":\"MetricsLogger.Emitted metric\",\"log_level\":0,\"data\":{\"metric\":{\"key\":\"follower/is_follower\",\"value\":0,\"unit\":\"boolean\",\"RawValue\":\"\",\"Error\":null}}}"
    ],
      "@version" => "1",
    "@timestamp" => "2019-08-29T06:38:19.033Z",
          "host" => [
        [0] "0.0.0.0",
        [1] "q-m84n2s0.q-g257.bosh"
    ],
          "path" => "/var/log/pcf.log",
          "type" => "pcf-log",
     "timestamp" => "2019-08-29T06:22:21.523509Z",
      "app_name" => "mysql-metrics",
       "proc_id" => "rs2",
       "director" => "172.16.0.20",
    "deployment" => "service-instance_157b3f9e-f631-42ae-8d5b-88aa9e3ee2ec",
          "tags" => []
}
```
now you are ready to analyize pcf logs

ref: http://man7.org/linux/man-pages/man5/rsyslog.conf.5.html
