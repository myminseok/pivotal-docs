
#### ssh into opsman VM
```
chmod 600 opsman.key 
ssh -i opsman.key ubuntu@opsmanager.mkim-tas.pcfdemo.net

```
####  create env.yml for om
This file contains properties for targeting and logging into the Ops Manager API. 
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#basic-authentication
- https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/configuring-env.html

``` yaml
---
target: ((opsman_target))
connect-timeout: 30                 # default 5
request-timeout: 3600               # default 1800
skip-ssl-validation: true           # default false
username: ((opsman_admin.username))
password: ((opsman_admin.password))
decryption-passphrase: ((decryption-passphrase))
```

#### download om linux cli
- https://github.com/pivotal-cf/om/releases

#### configure product config 
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

now gorouter vm should be registered to web-lb target group automatically. diego-brain vm  to ssh-lb.


