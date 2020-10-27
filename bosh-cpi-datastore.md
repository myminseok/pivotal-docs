- https://bosh.io/docs/cpi-config/
- https://www.starkandwayne.com/blog/multi-cpi-bosh-one-bosh-to-rule-them-all/

```
cpi <----- stemcell
    <----- datastore> vm disk
    <----- datastore> persistent_disk
    
```
## 1. Deploying bosh VM

```
bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -o bosh-deployment/jumpbox-user.yml \
    -o bosh-deployment/uaa.yml \
    -o bosh-deployment/bbr.yml \
    -o bosh-deployment/credhub.yml \
    -o bosh-deployment/misc/config-server.yml \
    -o bosh-deployment/misc/dns.yml \
    -v director_name=bosh-1 \
    -v internal_cidr=10.10.0.0/16 \
    -v internal_gw=10.10.10.1 \
    -v internal_ip=10.10.10.50 \
    -v internal_dns="[8.8.8.8]" \
    -v network_name="VM Network" \
    -v vcenter_dc=Datacenter \
    -v vcenter_ds=datastore1 \                 <== datastore1
    -v vcenter_ip=10.10.10.10 \
    -v vcenter_user=administrator@vsphere.local \
    -v vcenter_password=PASSWORD \
    -v vcenter_templates=bosh-1-templates \
    -v vcenter_vms=bosh-1-vms \
    -v vcenter_disks=bosh-1-disks \
    -v vcenter_cluster=Cluster
 ```
> above command will create a director vm on datastore1.

- In the bosh vm, there is cpi config as following:

```
bosh/0:/var/vcap/jobs/vsphere_cpi/config# cat cpi.json

{
  "cloud": {
    "plugin": "vsphere",
    "properties": {
      "vcenters": [
        {
          "host": "10.10.10.10",
          "user": "administrator@vsphere.local",
          "password": "PASSWORD",
          "datacenters": [
            {
              "name": "Datacenter",
              "vm_folder": "bosh-1-vms",
              "template_folder": "bosh-1-templates",
              "disk_path": "bosh-1-disks",
              "datastore_pattern": "datastore1",             <== datastore1
              "persistent_datastore_pattern": "datastore1",   <== datastore1
              "allow_mixed_datastores": true,
              "clusters": [
                {
                  "Cluster": {}
                }
              ]
            }
          ],
          "default_disk_type": "preallocated",
          "enable_auto_anti_affinity_drs_rules": false,
          "upgrade_hw_version": false,
          "enable_human_readable_name": true,
          "http_logging": false
        }
      ],
      "agent": {
        "ntp": [
          "0.pool.ntp.org",
          "1.pool.ntp.org"
        ],
        "blobstore": {
          "provider": "dav",
          "options": {
            "endpoint": "http://10.10.10.50:25250",
            "user": "agent",
            "password": "2bnhzl7ckfs69te84g29"
          }
        },
        "mbus": "nats://nats:myz3aq5nt80grb877g97@10.10.10.50:4222"
      }
    }
  }
}

```
> if you deploy bosh release, then the deployment will use cpi.json information to place vm and datastore.




## Defining cpi-config for bosh release deployment
- cpi.json in bosh vm is default cpi config used for deploying bosh releases by bosh. 
- To use multi-cpis by overriding default cpi.json, you need to define cpi-config and cloud-config.

``` cpi-config.yml
cpis:
- name: cpi1
  properties:
    datacenters:
    - allow_mixed_datastores: true
      clusters:
      - Cluster: {}
      datastore_pattern: datastore2.                   <== datastore2
      disk_path: bosh-1-disks
      name: Datacenter
      persistent_datastore_pattern: datastore2
      template_folder: bosh-1-templates
      vm_folder: bosh-1-vms
    default_disk_type: preallocated
    host: 10.10.10.10
    enable_human_readable_name: true
    password: PASSWORD
    user: administrator@vsphere.local
  type: vsphere
 
  
```

``` cloud-config.yml
azs:
- name: mgmt-az
  cpi: cpi1                     <===== map to cpi name in cpi-config.
  cloud_properties:
    datacenters:
    - clusters: [ "Cluster": {}]
    
vm_types:
- name: default
  cloud_properties:
    cpu: 2
    ram: 1024
    disk: 30_000
- name: large
  cloud_properties:
    cpu: 2
    ram: 4096
    disk: 30_240

disk_types:
- name: default
  disk_size: 3000
- name: large
  disk_size: 50_000

networks:
- name: default
  type: manual
  subnets:
  - range: 10.10.10.0/24
    gateway: 10.10.10.1
    azs: [z1]
    dns: [8.8.8.8]
    reserved: [10.10.10.0-10.10.10.60]
    cloud_properties:
      name: "VM Network"

compilation:
  workers: 5
  reuse_compilation_vms: true
  az: z1
  vm_type: default
```


### bind Stemcells to cpi.

- upload stemcells to the new cpis by `bosh upload-stemcell`
- if multi-cpi, then `bosh upload-stemcell` will upload to all CPIs.

```
root@ubuntu:/data/bosh-1# bosh stemcells
Using environment '10.10.10.50' as client 'admin'

Name                                      Version  OS             CPI                 CID
bosh-vsphere-esxi-ubuntu-xenial-go_agent  621.90*  ubuntu-xenial  -                   sc-f90a2cdb-e6d9-4196-9d3a-0e985ec039ad
~                                         621.90*  ubuntu-xenial  cpi1                sc-8ce2178b-3967-4bfa-bca7-7bd1f0e04dbb
                                          621.90   ubuntu-xenial  cpi2                sc-1b0bc4c5-af53-4a2b-b21f-f30283f32974

```



## missing bosh stemcell

if bosh lost it's stemcell on vsphere, then empty 'stemcells' section in `state.json', then redeploy bosh vm.

```

{
    "director_id": "48719fd7-7649-49e6-7390-23f47f80b186",
    "installation_id": "c42a252e-1871-4779-5ed4-19d525b0de72",
    "current_vm_cid": "",
    "current_stemcell_id": "",
    "current_disk_id": "cdd9a15c-ea72-4acc-6df6-06a02d405fe0",
    "current_release_ids": [],
    "current_manifest_sha": "",
    "disks": [
        {
            "id": "cdd9a15c-ea72-4acc-6df6-06a02d405fe0",
            "cid": "disk-be05f888-7482-4ee7-b6ce-eed0b6763f1d",
            "size": 65536,
            "cloud_properties": {}
        }
    ],
     "stemcells": [
        {
            "id": "c9103ae1-0feb-4c38-61c2-9eb4c522209e",
            "name": "bosh-vsphere-esxi-ubuntu-xenial-go_agent",
            "version": "621.85",
            "api_version": 3,
            "cid": "sc-8cf0729b-fb40-487e-a63b-a9228648fdff"
        }
    ],
    "releases": []
    
```
    
