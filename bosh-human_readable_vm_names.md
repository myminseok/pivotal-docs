
Enabling human readable vm name for bosh managed VMs through Pivotal Cloud Foundry Ops Manager.
- it tested on PCF 2.4+


### get your opsman uaa token
https://docs.pivotal.io/pivotalcf/2-5/customizing/opsman-users.html
```
uaac context

export TOKEN=<YOUR-OPSMAN-UAA-TOKEN>

```

### Enable 'human_readable_vm_names' option to opsman
https://docs.pivotal.io/pivotalcf/2-5/opsman-api/#updating-single-iaas-configuration
```

curl -k "https://localhost/api/v0/staged/director/iaas_configurations" -H "Authorization: Bearer $TOKEN"  | jq ‘.'


curl -k "https://localhost/api/v0/staged/director/iaas_configurations/6552ba16572953313cea" -H "Authorization: Bearer $TOKEN" -X PUT   -H "Content-Type: application/json" \
-d '{
  "iaas_configuration":
    {
      "guid": "6552ba16572953313cea",
      "name": "default",
      "additional_cloud_properties": {"human_readable_vm_names":true},
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

```

### apply to director


###

```
ubuntu@opsman-pcfdemo-net:~$ bosh cpi-config
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
    human_readable_vm_names: true
    password:  
    user: 
  type: vsphere

Succeeded
```
