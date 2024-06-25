# RLP Message Loss Rate

## Dropped Message metrics / logs
the number of Doppler VMs scale limit - 40 VMs. We don't recommend scaling out beyond this number.
One approach to identifying applications that have a particularly large number of logs/metrics would be to use the Log Cache cf CLI plugin and the cf log-meta command:
```
$ cf install-plugin -r CF-Community "log-cache"
$ cf log-meta --noise --sort-by rate
```
This will only show the counts of logs and metrics that have successfully made it to Log Cache but could give an idea of applications that have a particularly large number of metrics.

#### Tools (cf plugin)
https://github.com/cloudfoundry/log-cache-cli/releases/tag/v6.0.1
```
cf install-plugin -r CF-Community "log-cache"
```
https://github.com/cloudfoundry-community/firehose-plugin/releases/tag/0.13.0
```
cf install-plugin -r CF-Community "Firehose Plugin"
```

#### cf  "log-cache" plugin
https://github.com/cloudfoundry/log-cache-cli/releases/tag/v6.0.1
cf install-plugin -r CF-Community "log-cache"

run as cf admin
```
cf install-plugin -r CF-Community "log-cache"
```

```
cf tail -f doppler -c metrics 
2024-05-27T07:34:54.49+0000 [doppler] COUNTER dropped:1000
2024-05-27T07:43:34.39+0000 [doppler] GAUGE subscriptions:10.000000 subscriptions
2024-05-27T07:43:34.39+0000 [doppler] COUNTER egress:0
2024-05-27T07:43:39.39+0000 [doppler] COUNTER ingress:8315506
2024-05-27T07:43:39.40+0000 [doppler] COUNTER egress:35757
2024-05-27T07:43:39.40+0000 [doppler] COUNTER dropped:0
```

```
cf tail -f doppler -c metrics --json | jq .
```

```
cf tail -f reverse_log_proxy -c metrics

Retrieving logs for source reverse_log_proxy as admin...

2024-06-24T13:57:44.47+0000 [reverse_log_proxy] COUNTER ingress:831058957
2024-06-24T13:57:44.47+0000 [reverse_log_proxy] GAUGE subscriptions:10.000000 total
2024-06-24T13:57:44.47+0000 [reverse_log_proxy] COUNTER egress:831058719
2024-06-24T13:58:44.47+0000 [reverse_log_proxy] COUNTER log_router_connects:0
2024-06-24T13:58:44.47+0000 [reverse_log_proxy] COUNTER dropped:0
2024-06-24T13:58:44.47+0000 [reverse_log_proxy] GAUGE subscriptions:10.000000 total
2024-06-24T13:58:44.47+0000 [reverse_log_proxy] COUNTER egress:831191993
2024-06-24T13:58:44.47+0000 [reverse_log_proxy] COUNTER log_router_disconnects:0
2024-06-24T13:58:44.47+0000 [reverse_log_proxy] COUNTER rejected_streams:0
2024-06-24T13:58:44.47+0000 [reverse_log_proxy] COUNTER ingress:831192174
```

```
cf log-meta
```

#### cf "Firehose Plugin"
https://github.com/cloudfoundry-community/firehose-plugin/releases/tag/0.13.0

```
cf install-plugin -r CF-Community "Firehose Plugin"
```


```
cf nozzle -f CounterEvent | grep 'loggregator.doppler' | grep dropped | grep ingress

origin:"loggregator.doppler" eventType:CounterEvent timestamp:1719237858885394593 deployment:"cf-edc5e09298dc349e5048" job:"doppler" index:"b0ca461b-08f5-4b8a-9e91-2560254f4ce5" ip:"10.1.4.28" tags:<key:"metric_version" value:"2.0" > tags:<key:"product" value:"VMware Tanzu Application Service" > tags:<key:"source_id" value:"doppler" > tags:<key:"system_domain" value:"sys.ds.lab" > counterEvent:<name:"egress" delta:7181 total:24889 >
```

```
cf nozzle -f LogMessage | grep "app instance exceeded log rate limit"
```

### Doppler logs (Doppler VM)

```
2024/05/15 04:53:14.198417 Dropped 1000 envelopes (v2 buffer) ShardID: filebeat-860v2-sys1-PCFECK
2024/05/15 04:53:15.010896 Dropped 55000 envelopes (v1 buffer) ShardID: 1715741349
2024/05/15 04:53:15.795315 Dropped 36000 envelopes (v1 buffer) ShardID: 1715733771
2024/05/15 04:53:17.530145 Dropped 47000 envelopes (v1 buffer) ShardID: 1715746034
2024/05/15 04:53:18.584213 Dropped 1000 envelopes (v2 buffer) ShardID: metric-store

2024/05/15 05:04:16.707647 Dropped 1000 envelopes (v1 buffer) ShardID: filebeat-cbgm-7-10-v1-subscrption-id-99999
```

ShardID
```
tas_exporter
filebeat
metricbeat
metric-store
```

### How to correlate the subscription id with the nozzle 
https://knowledge.broadcom.com/external/article/298276/how-to-correlate-the-subscription-id-wit.html

1 - Find the index of the rlp that is dropping most by tracking the rlp.dropped metric in your metric ingestion system
2 - ssh on the instance and find the connected IP addresses:
```
loggregator_trafficcontroller/b588ed10-179a-4bb4-874d-f6c7b031ddc3:/var/vcap/sys/log/reverse_log_proxy_gateway# netstat -ant | grep $(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1):8082
tcp        0      0 10.225.61.15:8082       10.84.231.49:55309      ESTABLISHED
```

## Loggregator Firehose Config

#### Doppler config (Doppler VM)
```
/var/vcap/jobs/doppler/config/bpm.yml
    INGRESS_BUFFER_SIZE: "10000"
    EGRESS_BUFFER_SIZE: "1000"
```

#### RLP config (loggregator_trafficcontroller VM)
```
/var/vcap/jobs/reverse_log_proxy/config/bpm.yml
    MAX_EGRESS_STREAMS: "1000"
```

## Firenoze Nozzles

### Healthwatch2 tas exporter (metric nozzle)
collects metrics from Loggregator firehose RLP
https://docs.vmware.com/en/Healthwatch-for-VMware-Tanzu/2.2/healthwatch/architecture.html

```
pas-exporter-counter/24967799-0c4c-4f05-aeb8-8f0f56b0bb45:/var/vcap/jobs/pas-exporter/config/certs# 
curl -sk --cert ./exporter-certificate.pem --key ./exporter-certificate.key --cacert ./exporter-ca.pem https://localhost:9090/metrics | grep reverse_log_proxy >
```

### metric store (metric nozzle)
collects metrics from Loggregator firehose RLP
https://tanzu.vmware.com/content/blog/metric-store-a-cloud-native-time-series-database-for-cloud-foundry


### App Metrics (log nozzle)
collects logs from Loggregator firehose RLP
https://docs.vmware.com/en/App-Metrics-for-VMware-Tanzu/2.2/app-metrics/GUID-using.html#logs-20 

#### WARNING: "Do not forward app logs to the Firehose"
- Activating "Do not forward app logs to the Firehose" on TAS tile will set to diegocellvm > loggregator_agent> LOGS_DISABLED=true >  
- and it will stop forwarding app logs from diego cell to doppler vm 
- and eventually app metric tile won't be able to subscribe app logs.

#### app metric nozzle ShardID
log-store-vms > /var/vcap/jobs/nozzle/config/bpm.yml
```
processes:
- name: nozzle
    executable: /var/vcap/packages/nozzle/nozzle
    env:
    LOG_API_ADDR: "q-s0.loggregator-trafficcontroller.net40.cf-edc5e09298dc349
e5048.bosh:8082"
    LOG_API_SHARD_ID: "PULT1qKxzmw8abqPe0ZPOgKqVhYnCy"

```

### filebeat (log nozzle)
```
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.13.4-linux-x86_64.tar.gz
tar xzvf filebeat-8.13.4-linux-x86_64.tar.gz
cd filebeat-8.13.4-linux-x86_64
curl -L -O https://raw.githubusercontent.com/elastic/beats/8.13/deploy/cloudfoundry/filebeat/filebeat.yml
curl -L -O https://raw.githubusercontent.com/elastic/beats/8.13/deploy/cloudfoundry/filebeat/manifest.yml
```

https://www.elastic.co/kr/blog/how-to-tune-elastic-beats-performance-a-practical-example-with-batch-size-worker-count-and-more
```
output.logstash:
# Number of batches to be sent asynchronously to Logstash while processing
# new batches.
#pipelining: 2

```

### firehose-to-syslog
https://github.com/cloudfoundry-community/firehose-to-syslog

## Supporting larger metric volumes(applied TAS 3.0)
- Balancing is performed for metric registrar scraping, but as you point out it is application based (per registration).
- This means that if a specific application has an outsized number of metrics the endpoint worker handling it will emit an outsized number of metrics.
- Batches larger than 10k metrics are likely to cause dropping. Generally a single endpoint does not have 10k metrics, and polling the next metric endpoint provides enough of a delay for the forwarder agent's buffer to empty.
we provide the app log rate limit feature per app as below since TAS 3.0.
https://docs.vmware.com/en/VMware-Tanzu-Application-Service/4.0/tas-for-vms/app-log-rate-limits.html

### Configure Aggregate syslog drain destinations
https://docs.vmware.com/en/VMware-Tanzu-Application-Service/4.0/tas-for-vms/configure-pas.html#configure-system-logging-optional-17
```
so following is suggestion for now..
Deactivate Enable V1 Firehose.
Activate Enable V2 Firehose.
Deactivate Do not forward app logs to the Firehose.
Configure Aggregate syslog drain destinations.
```

