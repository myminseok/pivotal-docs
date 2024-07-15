
#### ssh into opsman VM
```
chmod 600 opsman.key 
ssh -i opsman.key ubuntu@opsmanager.mkim-tas.pcfdemo.net

```
####  create env.yml for om
This file contains properties for targeting and logging into the Ops Manager API. 
#### env.yml
https://docs.vmware.com/en/Platform-Automation-Toolkit-for-VMware-Tanzu/5.1/vmware-automation-toolkit/GUID-docs-how-to-guides-configuring-env.html

``` yaml
---
target:
connect-timeout: 30                 # default 5
request-timeout: 3600               # default 1800
skip-ssl-validation: true           # default false
username: 
password: 
decryption-passphrase: 
```

#### download om linux cli
- https://github.com/pivotal-cf/om/releases
  
#### check swap status on diegocell

```
$ bosh -d cf-54c9c2f906b6aba996cd ssh diego_cell/0
```

free
```
diego_cell/d097fe0e-0357-4698-b887-c0af632417a8:~$ free -m
              total        used        free      shared  buff/cache   available
Mem:          32168        5893        2940        1723       23334       23614
Swap:         32167           8       32159
```

#### configure swap via opsmanager product config 
fetch product guid
```
om -e env.yml curl -p /api/v0/staged/products
```
fetch product diegocell job id.
```
om -e env.yml curl -p /api/v0/staged/products/cf-edc5e09298dc349e5048/jobs
```
fetch resource_config of diegocell job.
```
om -e env.yml curl -p /api/v0/staged/products/cf-edc5e09298dc349e5048/jobs/diego_cell-5153f061269326de270f/resource_config
```
save output and edit
``` yaml
{
  "instance_type": {
    "id": "automatic"
  },
  "instances": 12,
  "additional_networks": [
    {
      "guid": "346ee68001f288a9f5f8"
    },
    {
      "guid": "ff728d01eb0cb2aacbfa"
    }
  ],
  "nsx": {
    "security_groups": [],
    "lbs": []
  },
  "nsxt": {
    "ns_groups": [],
    "vif_type": null,
    "lb": {
      "server_pools": []
    }
  },
  "additional_vm_extensions": [],
  "swap_as_percent_of_memory_size": "automatic" 0 # <=== set to 0
}
```

update using curl instead of om cli.
```
curl -k https://<opsman.domain.url>/api/v0/staged/products/cf-7b6a32f059ba9157bb8f/jobs/diego_cell-0bbd3e7931b651cfc62c/resource_config \
-H "Authorization: bearer $UAA_TOKEN" \
-X PUT \
-H "Content-type: application/json" \
-d@resource_config_deigocell.txt -k -vv
```



