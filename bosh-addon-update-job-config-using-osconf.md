

this document explains how to update job config from the bosh deployed vm using [os-conf-release](https://github.com/cloudfoundry/os-conf-release) by leveraging bosh [runtime-config](https://bosh.io/docs/runtime-config/). also it would be useful to understand how [bosh job lifecycle works](https://bosh.io/docs/job-lifecycle/)


## How to apply
following example explains how to update `/var/vcap/jobs/pas-exporter/config/bpm.yml` file from PAS-exporter gauge VM in healthwath exporter deployment in particular, replace `-XX:MaxRAMPercentage=80.0` (default) to any number as preferred

### Create runtime-config
create a `osconf_healthwatch_exporter.yml` as following.

```
releases:
- name: os-conf
  version: 22.3.1                                        #<===== 1) should match the release version.

addons:
- name: os-configuration
  include:
    deployments:
    - p-healthwatch2-pas-exporter-def848648904f0938bce     #<===== 2) replace with actual deployment name
    instance_groups:
    - pas-exporter-gauge                                   #<===== 3) make sure the target instance groups(VM)

  jobs:
  - name: pre-start-script
    release: os-conf
    properties:
      script: |-
        #!/bin/bash

        CUSTOM_SCRIPT_PATH=/var/vcap/jobs/pas-exporter/config/update_bpm_osconf.sh
        cat > $CUSTOM_SCRIPT_PATH <<EOF
        #!/bin/bash
        SOURCE="/var/vcap/jobs/pas-exporter/config/bpm.yml"
        cat \$SOURCE | sed 's/MaxRAMPercentage=...0/MaxRAMPercentage=60.0/g' > \${SOURCE}.tmp    #<===== 4) replace with desired value
        mv \${SOURCE}.tmp \${SOURCE}
        rm -rf \${SOURCE}.tmp
        EOF
        chmod +x $CUSTOM_SCRIPT_PATH
        sh $CUSTOM_SCRIPT_PATH
```

### create a runtime-config
```
bosh update-runtime-config --name=osconf_healthwatch_exporter ./osconf_healthwatch_exporter.yml
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
59*  runtime  osconf_healthwatch_exporter               -     2025-08-28 07:08:10 UTC
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
### apply change the healthwatch exporter deployment from opsmanager UI or bosh cli.

now bosh deploy should include the new runtime config into the deployment. 

```
bosh -d p-healthwatch2-pas-exporter-def848648904f0938bce deploy ./healthwatch-exporter.yml
```

during the apply change, the `pre-start-script` job from the runtime config above will create `/var/vcap/jobs/pre-start-script/bin/pre-start` file in the target deployment and it run before the jobs are starting by [bosh job lifecycle design](https://bosh.io/docs/job-lifecycle/)
and it updates `/var/vcap/jobs/pas-exporter/config/bpm.yml` file with new value.

```
pas-exporter-gauge/85734dc6-62ea-4127-bf20-1b224092e89b:~$ cat /var/vcap/jobs/pas-exporter/config/bpm.yml
---
processes:
- name: pas-exporter
  executable: "/var/vcap/packages/pas-exporter/bin/pas-exporter"
  env:
    DEPLOYMENT: p-healthwatch2-pas-exporter-def848648904f0938bce
    ENABLE_COUNTERS: 'false'
    ENABLE_GAUGES: true
    ENABLE_TIMERS: 'false'
    ENABLE_SPIKE_TIMERS: 'true'
    ENABLE_CONTAINER_METRICS: true
    DISABLE_RABBIT_PER_OBJECT_METRICS: 'false'
    GOROUTER_LATENCY_METRICS_STRATEGY: GAUGE
    EXPORTER_CA_CERT_PATH: "/var/vcap/jobs/pas-exporter/config/certs/exporter-ca.pem"
    EXPORTER_EGRESS_PORT: 9090
    EXPORTER_SERVER_CERT_PATH: "/var/vcap/jobs/pas-exporter/config/certs/exporter-certificate.pem"
    EXPORTER_SERVER_KEY_PATH: "/var/vcap/jobs/pas-exporter/config/certs/exporter-certificate-pkcs8.key"
    INSTANCE_ID: 85734dc6-62ea-4127-bf20-1b224092e89b
    IP: 192.168.0.79
    JAVA_HOME: "/var/vcap/packages/openjdk"
    JAVA_OPTS: "-Dio.netty.native.workdir=/var/vcap/data/pas-exporter/netty-workdir
      -XX:MaxRAMPercentage=60.0"
    JOB: pas-exporter-gauge
    RLP_CA_CERT_PATH: "/var/vcap/jobs/pas-exporter/config/certs/rlp-ca.pem"
    RLP_CLIENT_CERT_PATH: "/var/vcap/jobs/pas-exporter/config/certs/rlp-certificate.pem"
    RLP_CLIENT_KEY_PATH: "/var/vcap/jobs/pas-exporter/config/certs/rlp-certificate-pkcs8.key"
    RLP_HOST: q-s0.loggregator-trafficcontroller.network.cf-05c0b7494ba8ddb50eb8.bosh
    RLP_PORT: 8082
    RLP_SERVER_NAME: reverselogproxy
    EXPIRATION_SECONDS: '300'
    SKIP_CUSTOM_APP_METRICS: false
  additional_volumes:
  - path: "/var/vcap/data/pas-exporter/netty-workdir"
    writable: true
    allow_executions: true
  hooks:
    pre_start: "/var/vcap/jobs/pas-exporter/bin/pre-start.sh"
    ```
