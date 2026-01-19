# platform log forwarding to multiple external syslog endpoint 
forwarding platform logs to additional syslog remotes using syslog-release is described in this [syslog-release document](https://github.com/cloudfoundry/syslog-release/blob/main/examples/example-custom-rules.md#forwarding-to-additional-remotes)
This document describe a solution how to achive above goal.

## Consideration (os-conf vs custom release)

### [option1] using os-conf bosh release
the simplist option is using `pre-start-script` of [os-conf-release](https://github.com/cloudfoundry/os-conf-release) bosh relase but if the job is alreay deployed, then it is not possible to deploy another job with the same name on the same VM in a deployment.

* BOSH add-on results in error Colocated job is already added to the instance group
if you are trying to apply two "pre-start-script" jobs from os-conf to a deployment, errors are thrown as described in [KB](https://knowledge.broadcom.com/external/article/387226/bosh-addon-results-in-error-colocated-jo.html)

### [option2] using customer bosh release
above limit can be overcome by creating custom bosh release with unique job name.
please refer to [custom-release](https://github.com/myminseok/custom-release/tree/main) and [sample runtime-config](https://github.com/myminseok/custom-release/blob/main/runtimeconfig.yml)

## How to apply
#### Create runtime-config
create a `custom_syslog_forwarder.yml` as following.

```
     
cat > custom_syslog_forwarder.yml << EOF

releases:
- name: os-conf                           #<===== (1) if os-conf release is alreay applied, then use custom release
  version: 22.3.1                         #<===== (2) should match the release version.

addons:
- name: custom_syslog_forwarder_addon
  include:                                                #<===== (3) it would be applied to all vms without include section, 
    deployments:
    - cf-605f23577312b57a2f91                             #<===== (4) replace with actual deployment name list (no error arise even with no existing name)
    - p-isolation-segment-is1-7b2174cae92b12796f0a
    instance_groups:
    - uaa                                              #<===== (5) make sure the target instance group(VM) list (no error arise even with no existing name)
    - isolated_router_is1

  jobs:
  - name: pre-start-script
    release: os-conf
    properties:
      script: |-
        #!/bin/bash
        ## <===== make sure no space above the /bin/bash

        cat > /etc/rsyslog.d/36-custom.conf << EOF

        ## forward logs containers any of following keywords (OR condition)
        if not (\\\$msg contains_i ["audit", "user=", "ssh", "v3/roles", "password" ] ) then stop      #<===== (6) add/replace keyword list to be forwarded logs that contains.
        
        *.* action(type="omfwd"
                  protocol="tcp"
                  queue.type="linkedList"
                  Target="192.168.0.6"               #<===== (7) replace with actual syslog endpoint ip
                  Port="514"                         #<===== (8) replace with actual syslog endpoint port
                  StreamDriverMode="0"               #<===== (9)) "0" for non tls
                  Template="SyslogForwarderTemplate"
                  )
        EOF

EOF

```


#### Create a runtime-config
```
bosh update-runtime-config --name=custom_syslog_forwarder_addon ./custom_syslog_forwarder.yml
```

verify the created addon config `custom_syslog_forwarder_addon`.
```
ubuntu@opsmanager-3-0:~/workspace$ bosh configs
Using environment '192.168.0.55' as client 'ops_manager'

ID    Type     Name                                                          Team  Created At
144*  cloud    default                                                       -     2025-12-19 03:38:23 UTC
149*  cpi      default                                                       -     2026-01-02 03:37:59 UTC
139*  runtime  cf-605f23577312b57a2f91-bosh-dns-aliases                      -     2025-12-17 06:27:15 UTC
154*  runtime  custom_syslog_forwarder_addon                                 -     2026-01-19 05:36:04 UTC
3*    runtime  director_runtime                                              -     2025-04-15 07:05:13 UTC
147*  runtime  ops_manager_dns_runtime                                       -     2026-01-02 03:37:56 UTC
148*  runtime  ops_manager_system_metrics_runtime                            -     2026-01-02 03:37:57 UTC
```

### Upload os-conf release to bosh-director
NOTE: skip following steps if there is os-conf release in bosh-director.

#### os-conf from tanzu opsmanager VM
```
bosh upload-release /var/tempest/internal_releases/os-conf

bosh releases | grep os-conf
os-conf                        	22.3.1             	b6900bc

```

#### download os-conf from public repo
```
wget https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=22.3.1
```

```
bosh upload-release ./os-conf-release\?v\=22.3.1

bosh releases | grep os-conf
os-conf                        	22.3.1            	b6900bc

```

### Apply change to deployment from opsmanager UI or bosh cli.

now bosh deploy should include the new runtime config into the deployment. 

```
bosh -d cf-605f23577312b57a2f91 manifest > cf.ym
bosh -d cf-605f23577312b57a2f91 deploy ./cf.yml
```

during the apply change, the `pre-start-script` job from the runtime config above will create `/var/vcap/jobs/pre-start-script/bin/pre-start` file in the target deployment and it run before the jobs are starting by [bosh job lifecycle design](https://bosh.io/docs/job-lifecycle/).


### Changes from the target VM.

## 36-custom.conf file should be created under /etc/rsyslog.d folder 
```
uaa/b5a1e009-1258-4d09-9882-28faa829fabb:/etc/rsyslog.d# ll
total 44
drwxr-xr-x  2 root root 4096 Jan 19 02:31 ./
drwxr-xr-x 86 root root 4096 Jan 19 01:47 ../
-rw-r--r--  1 root root 1559 Dec 19 03:49 20-syslog-release.conf
-rw-r--r--  1 root root 1731 Jan 19 01:26 25-syslog-release-forwarding-setup.conf
-rw-r--r--  1 root root   86 Jan 19 02:28 30-syslog-release-custom-rules.conf
-rw-r--r--  1 root root    1 Dec 19 03:49 32-syslog-release-vcap-filter.conf
-rw-r--r--  1 root root    1 Dec 19 03:49 33-syslog-release-debug-filter.conf
-rw-r--r--  1 root root   73 Jan 19 02:31 35-syslog-release-forwarding-rules.conf
-rw-r--r--  1 root root  231 Jan 19 02:30 36-custom.conf
-rw-r--r--  1 root root  263 Dec 19 03:49 40-syslog-release-file-exclusion.conf
-rw-r--r--  1 root root 1864 Nov  1 12:30 50-default.conf
```


## (WIP) VM resource consumption

```

ps -eo %cpu,%mem,pid,pgid,tid,user,rss,cmd --sort %cpu

```




## How to delete the addon from deployment
multi steps are required to remove config files non bosh standard location other than /var/vcap folder.

#### (Step1) Create runtime-config to delete files.

create a `custom_syslog_forwarder.yml` as following.

```

cat > custom_syslog_forwarder.yml << EOF
releases:
- name: custom-release
  version: 1.0.0                                       #<===== 1) should match the release version.

addons:
- name: custom_syslog_forwarder_addon
  include:
    deployments:
    - cf-605f23577312b57a2f91                             #<===== 2) replace with actual deployment name list (no error arise even with no existing name)
    - p-isolation-segment-is1-7b2174cae92b12796f0a
    instance_groups:
    - uaa                                              #<===== 3) make sure the target instance group(VM) list (no error arise even with no existing name)
    - isolated_router_is1

  jobs:
  - name: custom-pre-start-script
    release: custom-release
    properties:
      script: |-
        #!/bin/bash
        rm -rf /etc/rsyslog.d/36-custom.conf 
EOF

```

and re-deploy the deployment.
```
bosh -d cf-605f23577312b57a2f91 manifest > cf.yml
bosh -d cf-605f23577312b57a2f91 deploy ./cf.yml
```


#### (Step2) delete the runtime config itself

```
bosh delete-config --type runtime --name custom_syslog_forwarder_addon
```
> note that bosh delete-config CONFIG_ID doesnot work.

make sure the config is deleted
```
bosh configs

```
and re-deploy the deployment.
```
bosh -d cf-605f23577312b57a2f91 manifest > cf.ym
bosh -d cf-605f23577312b57a2f91 deploy ./cf.yml
```
#### Troubleshooting

if the VM fails to configure jobs and start, then recreate the vm.
```
bosh -d cf-605f23577312b57a2f91 recreate uaa
```

