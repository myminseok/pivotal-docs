
Enabling human readable vm name for bosh managed VMs through Pivotal Cloud Foundry Ops Manager.

- https://bosh.io/docs/vsphere-human-readable-names/#more-about-human-readable-names
- for tas 2.9+(bosh vsphere cpi 53+) use "enable_human_readable_name"
- for tas 2.8 or older, use "human_readable_vm_names"

### get your opsman uaa token
https://docs.pivotal.io/pivotalcf/2-5/customizing/opsman-users.html
```
uaac target https://localhost/uaa
uaac token owner get

uaac contexts

export TOKEN=<YOUR-OPSMAN-UAA-TOKEN>

```

### How to enable option to opsman
https://docs.pivotal.io/pivotalcf/2-5/opsman-api/#updating-single-iaas-configuration

#### fetch your director iaas_configurations.
```
curl -k "https://localhost/api/v0/staged/director/iaas_configurations" \
 -H "Authorization: Bearer $TOKEN"  | jq '.'
```

#### update your director iaas_configurations.

for tas 2.8 or older older, use "human_readable_vm_names"

```
curl -k "https://localhost/api/v0/staged/director/iaas_configurations/6552ba16572953313cea" \
 -H "Authorization: Bearer $TOKEN" \
 -H "content-type: applicaton/json" \
 -X PUT   \
 -H "Content-Type: application/json" \
 -d '{
  "iaas_configuration":
    {
      "guid": "6552ba16572953313cea",
      "name": "default",
      "additional_cloud_properties": {"enable_human_readable_name":true},
      "vcenter_host": "<vcenter.url>",
      "datacenter": "<Datacentre>",
      "ephemeral_datastores_string": "<pcfstore>",
      "persistent_datastores_string": "<pcfstore>",
      "vcenter_username": "<vcenter account>",
      "bosh_vm_folder": "pcf_vms",
      "bosh_template_folder": "pcf_templates",
      "bosh_disk_path": "pcf_disk",
      "ssl_verification_enabled": false,
      "nsx_networking_enabled": false,
      "disk_type": "thick"
    }
}' -v

## or -d @file

* upload completely sent off: 704 out of 704 bytes
< HTTP/1.1 200 OK
...
<
* Connection #0 to host localhost left intact
{"iaas_configuration":{"guid":"6552ba16572953313cea","name":"default","additional_cloud_properties":{"enable_human_readable_name":true},"vcenter_host":"....","datacenter":"....","ephemeral_datastores_string":".....","persistent_datastores_string":"....","vcenter_username":"....@....","bosh_vm_folder":"...","bosh_template_folder":"....","bosh_disk_path":"....","ssl_verification_enabled":false,"nsx_networking_enabled":false,"disk_type":"thick"}}

```
### apply to director VM by clicking 'apply change' to director
- will recreate director vm.

### check director setting.
```
bosh cpi-config
Using environment '10.10.10.21' as client 'ops_manager'

cpis:
- migrated_from:
  - name: ""
  name: 6552ba16572953313cea
  properties:
    datacenters:
    - allow_mixed_datastores: true
      clusters:
      - cluster1: {}
      - cluster2: {}
      datastore_pattern:  
      disk_path: pcf_disk
      name: datacenter
      persistent_datastore_pattern:  
      template_folder: pcf_templates
      vm_folder: pcf_vms
    default_disk_type: preallocated
    host:  
    enable_human_readable_name: true
    password:  
    user: 
  type: vsphere

Succeeded
```
### now apply to bosh deployment by recreating vms.
- opsman > director tile> director config > check `recreate-vm' 
- apply change



# Method 2)

### edit env.yml

### extract director.yml 
```
om -e env.yml staged-director-config --no-redact > director.yml
```

### edit director.yml
```
az-configuration:
- name: AZ1
  iaas_configuration_name: default
  clusters:
  - cluster: Cluster
    drs_rule: MUST
    #guid: 0efe8967216700b594b9
    host_group: null
    resource_pool: null
    #  guid: 0f6de1676e51c1a01570
iaas-configurations:
- additional_cloud_properties: { "enable_human_readable_name":true}
  bosh_disk_path: pcf_disk
  bosh_template_folder: pcf_templates
  bosh_vm_folder: pcf_vms
...
```
### confiure director 
```
om -e env.yml configure-director -c director.yml
```

### verify configuration

```
# ssh into opsman vm
uaac target https://localhost/uaa --skip-ssl-validation
uaac token owner get

uaac curl -k "https://localhost/api/v0/staged/director/iaas_configurations"
{
  "iaas_configurations": [
    {
      "guid": "cfe2469c4b2e0848dbd9",
      "name": "default",
      "additional_cloud_properties": {
        "enable_human_readable_name": true
      },
      ...

```
### apply to director VM by clicking 'apply change' to director
- will recreate director vm.


