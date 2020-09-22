
Enabling human readable vm name for bosh managed VMs through Pivotal Cloud Foundry Ops Manager.
- it tested on PCF 2.7+
https://bosh.io/docs/vsphere-human-readable-names/#more-about-human-readable-names

### get your opsman uaa token
https://docs.pivotal.io/pivotalcf/2-5/customizing/opsman-users.html
```
uaac context

export TOKEN=<YOUR-OPSMAN-UAA-TOKEN>

```

### How to enable 'human_readable_vm_names' option to opsman
https://docs.pivotal.io/pivotalcf/2-5/opsman-api/#updating-single-iaas-configuration

#### fetch your director iaas_configurations.
```
curl -k "https://localhost/api/v0/staged/director/iaas_configurations" -H "Authorization: Bearer $TOKEN"  | jq '.'
```

#### update your director iaas_configurations.
```
curl -k "https://localhost/api/v0/staged/director/iaas_configurations/6552ba16572953313cea" -H "Authorization: Bearer $TOKEN" -H "content-type: applicaton/json" -X PUT   -H "Content-Type: application/json" \
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

