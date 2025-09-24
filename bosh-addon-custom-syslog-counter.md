


This document explains how to count `platform log volume per minute` as a `gauge` metric from bosh deployed vm, in particular for gorouter and display on grafana in healthwatch by leveraging [os-conf-release](https://github.com/cloudfoundry/os-conf-release) and [runtime-config](https://bosh.io/docs/runtime-config/). also it would be useful to understand how [bosh job lifecycle works](https://bosh.io/docs/job-lifecycle/)


## How to apply

### Create runtime-config
create a `osconf_custom_syslog_counter.yml` as following.

```
releases:
- name: os-conf
  version: 22.3.1                                        #<===== 1) should match the release version.

addons:
- name: os-configuration
  include:
    deployments:
    - cf-05c0b7494ba8ddb50eb8                             #<===== 2) replace with actual deployment name
    instance_groups:
    - router                                              #<===== 3) make sure the target instance groups(VM)

  jobs:
  - name: pre-start-script
    release: os-conf
    properties:
      script: |-
        #!/bin/bash                                      #<===== make sure no space above
        
        JOB_CONFIG_PATH=/var/vcap/jobs/custom-syslog-counter/config
        LOG_PATH=/var/vcap/sys/log/custom-syslog-counter
        if [ -d $JOB_CONFIG_PATH ]; then
            rm -rf $JOB_CONFIG_PATH
        fi
        mkdir -p $JOB_CONFIG_PATH
        mkdir -p $LOG_PATH

        ## create script.
        cat >  $JOB_CONFIG_PATH/custom_syslog_counter.sh <<EOF
        #!/bin/bash
        set -e
        JOB_CONFIG_PATH=/var/vcap/jobs/custom-syslog-counter/config
        SEARCH_BY_MIN=\$(date +"%Y-%m-%dT%H:%M")
        line_count=\$(find /var/vcap/sys/log/gorouter -name "*.log" | xargs grep -a "\$SEARCH_BY_MIN" | wc -l)  #<===== 4) customize filtering and counting logic
        ## line_count=\$(find /var/vcap/sys/log/gorouter -name "*.log" | xargs grep -a "\$SEARCH_BY_MIN" | grep "vcap_request_id" | wc -l)
        echo "# HELP custom_vm_syslog_line_min counted under /var/vcap/sys/log" > \$JOB_CONFIG_PATH/metrics
        echo "# TYPE custom_vm_syslog_line_min gauge" >> \$JOB_CONFIG_PATH/metrics
        echo "custom_vm_syslog_line_min \$line_count" >> \$JOB_CONFIG_PATH/metrics
        echo "\$SEARCH_BY_MIN \$line_count"
        EOF
        chmod +x $JOB_CONFIG_PATH/custom_syslog_counter.sh
        ## test run
        $JOB_CONFIG_PATH/custom_syslog_counter.sh


        ## configure prom_scraper
        cat >  $JOB_CONFIG_PATH/prom_scraper_config.yml <<EOF
        ---
        port: 10000
        source_id: "custom_syslog_counter"
        instance_id: $(hostname)
        scheme: http
        server_name: $(hostname -A | awk -F'.' '{print $2}')
        EOF

        ## run server serving syslog count metric.
        cd $JOB_CONFIG_PATH
        set +e && killall python3 2>/dev/null
        set -e
        nohup python3 -m http.server --directory /var/vcap/jobs/custom-syslog-counter/config  10000 >> /var/vcap/sys/log/custom-syslog-counter/custom_syslog_counter.log 2>&1 &

        ## to activate the custom metric
        chown -R root:vcap $JOB_CONFIG_PATH

        ## adding to crontab
        ####  run every 30 seconds, this prevents any delayed metric collection.
        CRON_JOB="* * * * * sleep 30; /var/vcap/jobs/custom-syslog-counter/config/custom_syslog_counter.sh >> /var/vcap/sys/log/custom-syslog-counter/custom_syslog_counter.log 2>&1"
        #### Check if the cron job already exists to prevent duplicates
        if ! crontab -l | grep -Fq "$CRON_JOB"; then
            # Add the cron job
            (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
            echo "Cron job added successfully."
        else
            echo "Cron job already exists."
        fi

        systemctl restart cron
```

### create a runtime-config
```
bosh update-runtime-config --name=osconf_custom_syslog_counter ./osconf_custom_syslog_counter.yml
```

bosh configs
```
ubuntu@opsmanager-3-0:~/workspace$ bosh configs
Using environment '192.168.0.55' as client 'ops_manager'

ID   Type     Name                                      Team  Created At
52*  cloud    default                                   -     2025-08-14 08:23:42 UTC
29*  cpi      default                                   -     2025-07-04 00:44:01 UTC
49*  runtime  cf-05c0b7494ba8ddb50eb8-bosh-dns-aliases  -     2025-08-04 03:04:52 UTC
50*  runtime  cf-05c0b7494ba8ddb50eb8-otel-collector    -     2025-08-04 03:05:02 UTC
3*   runtime  director_runtime                          -     2025-04-15 07:05:13 UTC
1*   runtime  ops_manager_dns_runtime                   -     2025-04-15 07:05:13 UTC
2*   runtime  ops_manager_system_metrics_runtime        -     2025-04-15 07:05:13 UTC
59*  runtime  osconf_custom_syslog_counter              -     2025-08-28 07:08:10 UTC
```

### upload os-conf release to bosh-director

#### tanzu opsmanager VM
```
bosh upload-release /var/tempest/internal_releases/os-conf

bosh releases | grep os-conf
os-conf                        	22.3.1*             	b6900bc

```

#### from oss release
```
wget https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=22.3.1
```

```
bosh upload-release ./os-conf-release\?v\=22.3.1

bosh releases | grep os-conf
os-conf                        	22.3.1            	a1905d6

```
### apply change to deployment from opsmanager UI or bosh cli.

now bosh deploy should include the new runtime config into the deployment. 

```
bosh  -d cf-05c0b7494ba8ddb50eb8 deploy ./cf.yml
```

during the apply change, the `pre-start-script` job from the runtime config above will create `/var/vcap/jobs/pre-start-script/bin/pre-start` file in the target deployment and it run before the jobs are starting by [bosh job lifecycle design](https://bosh.io/docs/job-lifecycle/)



### Changes from the target VM.

```
router/3956b231-0ec5-4dd9-9d76-c68a01604813:~# cat /var/vcap/jobs/custom-syslog-counter/config/custom_syslog_counter.sh
#!/bin/bash
set -e
JOB_CONFIG_PATH=/var/vcap/jobs/custom-syslog-counter/config
SEARCH_KEYWORD=$(date +"%Y-%m-%dT%H:%M")
line_count=$(find /var/vcap/sys/log/gorouter -name "*.log" | xargs grep -a "$SEARCH_KEYWORD" | wc -l)
echo "# HELP custom_vm_syslog_line_min counted under /var/vcap/sys/log" > $JOB_CONFIG_PATH/metrics
echo "# TYPE custom_vm_syslog_line_min counter" >> $JOB_CONFIG_PATH/metrics
echo "custom_vm_syslog_line_min $line_count" >> $JOB_CONFIG_PATH/metrics
echo "$SEARCH_KEYWORD $line_count"
```


```
router/3956b231-0ec5-4dd9-9d76-c68a01604813:~# crontab -l
* * * * * sleep 30; /var/vcap/jobs/custom-syslog-counter/config/custom_syslog_counter.sh >> /var/vcap/sys/log/custom-syslog-counter/custom_syslog_counter.log 2>&1
```

```
router/3956b231-0ec5-4dd9-9d76-c68a01604813:~# cat /var/vcap/jobs/custom-syslog-counter/config/metrics
# HELP custom_vm_syslog_line_min counted under /var/vcap/sys/log
# TYPE custom_vm_syslog_line_min counter
custom_vm_syslog_line_min 145
```

```
router/3956b231-0ec5-4dd9-9d76-c68a01604813:~# ps -ef | grep python3
root         514       1  0 01:28 ?        00:00:00 /usr/bin/python3 /usr/bin/networkd-dispatcher --run-startup-triggers
root       31692       1  0 02:09 ?        00:00:00 python3 -m http.server --directory /var/vcap/jobs/custom-syslog-counter/config 10000
root       33393    4034  0 02:21 pts/0    00:00:00 grep --color=auto python3
```

```
router/3956b231-0ec5-4dd9-9d76-c68a01604813:~# cat /var/vcap/jobs/custom-syslog-counter/config/prom_scraper_config.yml
---
port: 10000
source_id: "custom_syslog_counter"
instance_id: b58a0b0e-5122-4ce2-b877-7ba8a2cda970
scheme: http
server_name: router
```




```
router/3956b231-0ec5-4dd9-9d76-c68a01604813:~# monit summary
The Monit daemon 5.2.5 uptime: 14m

Process 'gorouter'                  running
Process 'gorouter-healthchecker'    running
Process 'loggregator_agent'         running
Process 'loggr-syslog-agent'        running
Process 'loggr-forwarder-agent'     running
Process 'loggr-udp-forwarder'       running
Process 'prom_scraper'              running
Process 'bosh-dns'                  running
Process 'bosh-dns-resolvconf'       running
Process 'bosh-dns-healthcheck'      running
Process 'system-metrics-agent'      running
Process 'otel-collector'            running
System 'system_b58a0b0e-5122-4ce2-b877-7ba8a2cda970' running
```


```
router/3956b231-0ec5-4dd9-9d76-c68a01604813:~# curl -k https://localhost:14821/metrics --cacert /var/vcap/jobs/prom_scraper/config/certs/scrape.crt --cert /var/vcap/jobs/prom_scraper/config/certs/scrape.crt --key /var/vcap/jobs/prom_scraper/config/certs/scrape.key

...

# HELP scrape_targets_total Total number of scrape targets identified from prom scraper config files.
# TYPE scrape_targets_total counter
scrape_targets_total 7
```

then, the metric `custom_vm_syslog_line_min` should be available from grafana dashboard.
