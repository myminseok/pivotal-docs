
===============
this document explains how to update job config from the bosh deployed vm using [os-conf-release](https://github.com/cloudfoundry/os-conf-release) by leveraging bosh [runtime-config](https://bosh.io/docs/runtime-config/). also it would be useful to understand how [bosh job lifecycle works](https://bosh.io/docs/job-lifecycle/)


## How to apply
following example explains how to update `/var/vcap/jobs/pas-exporter/config/bpm.yml` file from PAS-exporter gauge VM in healthwath exporter deployment in particular, replace `-XX:MaxRAMPercentage=80.0` (default) to any number as preferred

#### Create runtime-config
create a `osconf_healthwatch_exporter.yml` as following.

```
releases:
- name: os-conf
  version: 23.0.0                                         #<===== 1) should match the release version.

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

#### create a runtime-config
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

#### upload os-conf release to bosh-director

```
wget https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=23.0.0
```

```
bosh upload-release ./os-conf-release\?v\=23.0.0

bosh releases | grep os-conf
os-conf                        	23.0.0             	a1905d6

```
#### apply change the healthwatch exporter deployment from opsmanager UI or bosh cli.

now bosh deploy should include the new runtime config into the deployment. 

```
bosh -d p-healthwatch2-pas-exporter-def848648904f0938bce deploy ./healthwatch-exporter.yml
```

during the apply change, the `pre-start-script` job from the runtime config above will create `/var/vcap/jobs/pre-start-script/bin/pre-start` file in the target deployment and it run before the jobs are starting by [bosh job lifecycle design](https://bosh.io/docs/job-lifecycle/)
and it updates `/var/vcap/jobs/pas-exporter/config/bpm.yml` file with new value.

