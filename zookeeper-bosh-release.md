####  bosh cpi-config
```
$ bosh cpi-config

Using environment '10.0.1.6' as client 'admin'

No CPI config

Exit code 1
```
#### create EIP on AWS

#### bosh cloud-config
- https://github.com/cloudfoundry/bosh-deployment/blob/master/aws/cloud-config.yml
- cloud-config.yml
```
azs:
- name: ap-northeast-2a
  cloud_properties:
    availability_zone: ap-northeast-2a
vm_types:
- name: default
  cloud_properties:
    instance_type: t2.small
    ephemeral_disk: {size: 25_000}
- name: large
  cloud_properties:
    instance_type: m5.xlarge
    ephemeral_disk: {size: 50_000}

disk_types:
- name: default
  disk_size: 3000
- name: large
  disk_size: 50_000

networks:
- name: default
  type: manual
  subnets:
  - range: 10.0.1.0/24
    gateway: 10.0.1.1
    azs: [ap-northeast-2a]
    dns: [8.8.8.8]
    reserved: [10.0.1.1-10.0.1.20]
    static:
    - 10.0.1.100
    cloud_properties:
      subnet: subnet-0cac3dda4cc8305ef
- name: vip
  type: vip
  subnets:
  - azs: [ap-northeast-2a]
    static:
    - 3.34.71.61                     #   <=== EIP

compilation:
  workers: 5
  reuse_compilation_vms: true
  az: ap-northeast-2a
  vm_type: default
  network: default
```
update 
```
bosh update-cloud-config ./cloud-config.yml
```

#### zookeeper.yml
- aws vip guide: https://bosh.io/docs/networks/#vip
- zookeeper.yml
```
---
name: zookeeper

releases:
- name: zookeeper
  version: 0.0.10
  url: git+https://github.com/cppforlife/zookeeper-release

stemcells:
- alias: default
  os: ubuntu-xenial
  version: latest

update:
  canaries: 2
  max_in_flight: 1
  canary_watch_time: 5000-60000
  update_watch_time: 5000-60000

instance_groups:
- name: zookeeper
  azs: [ap-northeast-2a]
  instances: 1
  jobs:
  - name: zookeeper
    release: zookeeper
    provides:
      conn: {shared: true}
    properties: {}
  - name: status
    release: zookeeper
    properties: {}
  - name: smoke-tests
    release: zookeeper
    properties: {}
  vm_type: default
  stemcell: default
  persistent_disk: 10240
  networks:
  - name: default
    static_ips: [10.0.1.100]
    default: [dns, gateway]
  - name: vip                           #    <=== EIP
```


#### deploy.sh

```
ubuntu@ip-10-0-0-162:~/bosh-1$ cat deploy.sh
bosh create-env --recreate ./bosh-deployment/bosh.yml \
  --state=./state.json \
  --vars-store=./creds.yml \
  -o ./bosh-deployment/aws/cpi.yml \
  -o ./bosh-deployment/uaa.yml \
  -o ./bosh-deployment/jumpbox-user.yml \
  -v director_name=my-bosh \
  -v internal_cidr=10.0.1.0/24 \
    -v internal_gw=10.0.1.1 \
    -v internal_ip=10.0.1.6 \
    -v access_key_id=xxxx \
    -v secret_access_key=xxx \
    -v region=ap-northeast-2 \
    -v az=ap-northeast-2a \
    -v default_key_name=test-keypair \
    -v default_security_groups=[test-securitygroup] \
    --var-file private_key=~/test-keypair.pem \
    -v subnet_id=subnet-0cac3dda4cc8305ef
    
```

```
ubuntu@ip-10-0-0-162:~/zookeeper$ bosh vms
Using environment '10.0.1.6' as client 'admin'

Task 48. Done

Deployment 'zookeeper'

Instance                                        Process State  AZ               IPs         VM CID               VM Type  Active  Stemcell
zookeeper/1ef2aff2-a6ec-42d0-a985-f94ea032cfda  running        ap-northeast-2a  10.0.1.100  i-02ec42e5d081299f6  default  true    bosh-aws-xen-hvm-ubuntu-xenial-go_agent/621.74
                                                                                3.34.71.61
```                                                                             
                                                                               
                                                                               
