
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
diego cell 접속
$ bosh -d cf-54c9c2f906b6aba996cd ssh diego_cell/0
```

Type the following command to show swap usage summary by device
```
swapon -s
```

free
```
diego_cell/d097fe0e-0357-4698-b887-c0af632417a8:~$ free -m
              total        used        free      shared  buff/cache   available
Mem:          32168        5893        2940        1723       23334       23614
Swap:         32167           8       32159
```

#### configure swap via opsmanager product config 
```
om -e env.yml staged-config -p cf  > cf.yml
```

```
## om -e env.yml staged-config -p cf  -r false  -c true > cf.yml
```
vi cf.yml

``` yaml
...

diego_cell:
  ...
  "instance_type": {
    "id": "2xlarge"
  },
  "instances": 3, 
  "additional_networks": [],
  "nsx_security_groups": null,
  "nsx_lbs": [],
  "additional_vm_extensions": [],
  "swap_as_percent_of_memory_size": 0 # <=== set to 0
...

```
#### product config 
configure  director config in opsman VM.
```
om -e env.yml   configure-product -c cf.yml
```
```
configuring cf ...
```
then apply TAS change. 



