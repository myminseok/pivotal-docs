
# How to assign static IP to control VM in hub 10.3

This document expalins how to assign static IP to control VM in hub 10.3. Static IP assignment feature is coming on next hub release.

Please note that the static_ip bosh configuration will be reverted/removed on next apply change, but the assigned IPs will continue to be assigned.

- tested on  hub 10.3.6

## Procedures

### [Step1] configure static_ip bosh config

configure bosh cloud config with static IP list to be assigned to bosh deployed vms.

```
bosh cloud-config > cloud-config.yml
```


vi cloud-config.yml

```
networks:
- name: network
  subnets:
  - azs:
    - AZ1
    cloud_properties:
      name: VM Network
    dns:
    - 192.168.0.5
    gateway: 192.168.0.1
    range: 192.168.0.0/24
    reserved:
    - 192.168.0.1-192.168.0.54
    static:
    - 192.168.0.80
    - 192.168.0.81
    - 192.168.0.82
    - 192.168.0.83
    - 192.168.0.84
  type: manual

```


```
ubuntu@opsman321:~$ bosh update-cloud-config cloud-config.yml
Using environment '192.168.0.55' as client 'ops_manager'

  networks:
  - name: network
    subnets:
    - range: 192.168.0.0/24
      static:
+     - 192.168.0.80
+     - 192.168.0.81
+     - 192.168.0.82
+     - 192.168.0.83
+     - 192.168.0.84

Continue? [yN]:

```


### [Step2] re-deploy hub deployment with  static_ip ops file 


create ops file with static IP list to be assigned to ALL VMs in control instance group.

```
cat > hub-control-static-ip.yml<<EOF
- type: replace
  path: /instance_groups/name=control/networks/0/static_ips?
  value:
  - 192.168.0.80
  - 192.168.0.81
  - 192.168.0.82
  - 192.168.0.83
  - 192.168.0.84
EOF
```


fetch hub deployment manifest

```
bosh -d hub-2009ee622b5a9b9fe398 manifest > hub.yml
```

and re-deploy hub deployment with  static_ip ops file 

```
ubuntu@opsman321:~$   bosh -d hub-2009ee622b5a9b9fe398  deploy hub.yml -o hub-control-static-ip.yml
Using environment '192.168.0.55' as client 'ops_manager'

Using deployment 'hub-2009ee622b5a9b9fe398'

Release 'tanzu-platform/100.1.120' for stemcell 'ubuntu-jammy/1.1065' already exists.

Release 'antrea/2.4.3-build.1' for stemcell 'ubuntu-jammy/1.1065' already exists.

Release 'bpm/1.4.26' for stemcell 'ubuntu-jammy/1.1065' already exists.

Release 'tanzu-platform-registry-data/100.1.114' for stemcell 'ubuntu-jammy/1.1065' already exists.

Release 'kubo/1.23.0-build.30.1.23.x' for stemcell 'ubuntu-jammy/1.1065' already exists.


  networks:
  - name: network
    subnets:
    - range: 192.168.0.0/24
      static:
+     - 192.168.0.80
+     - 192.168.0.81
+     - 192.168.0.82
+     - 192.168.0.83
+     - 192.168.0.84

  instance_groups:
  - name: control
    networks:
    - name: network
+     static_ips:
+     - 192.168.0.80
+     - 192.168.0.81
+     - 192.168.0.82
+     - 192.168.0.83
+     - 192.168.0.84

Continue? [yN]: y

```