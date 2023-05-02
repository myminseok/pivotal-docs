
# (Only for public cloud) configure LB setting to opsman, director, TAS


## official guide
- https://docs.pivotal.io/application-service/2-10/operating/configure-lb.html
- https://docs.pivotal.io/ops-manager/2-10/aws/prepare-env-terraform.html

### [terraforming on aws via paving](terraforming-aws.md)

#### create opsman VM
(SECURITY WARNING!!! ) change opsmanager security group > inbound rule to myIP from ALL(0.0.0.0/0)
- AWS console> EC2> security groups
- network.pivotal.io.  check opsmanager AMI ID for your AWS region
- create opsman vm on public network which is created by paving.
- access opsman via opsman domain which is created by paving. ie) https://opsmanager.mkim-tas.pcfdemo.net

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

####  download om linux cli
- https://github.com/pivotal-cf/om/releases
```
wget https://github.com/pivotal-cf/om/releases/download/7.9.0/om-linux-amd64-7.9.0
```

#### set vm_extensions for loadbalancer, security groups
there are two options for setting vm_extensions. use either one that works.
- https://github.com/pivotal-cf/terraforming-aws/blob/master/ci/tasks/custom-vm-extensions.sh

##### OPTION 1) set vm_extensions to director.yml 
extract director.yml 
```
om -e env.yml staged-director-config --no-redact > director.yml
```
vi director.yml

``` yaml
az-configuration:
- name: ap-northeast-2a

... 

vmextensions-configuration:
- name: web-lb-security-groups
  cloud_properties:
    security_groups:
    - web_lb_security_group <== update to the actual aws security group.
    - vms_security_group    <== update to the actual aws security group.
- name: ssh-lb-security-groups
  cloud_properties:
    security_groups:
    - ssh_lb_security_group
    - vms_security_group
- name: tcp-lb-security-groups
 cloud_properties:
    security_groups:
    - tcp_lb_security_group
    - vms_security_group
vmtypes-configuration: {}
```
configure  director config in opsman VM.
```
om -e env.yml configure-director -c director.yml

```

##### OPTION 2) set vm_extensions via opsman API 

``` bash
om -e env.yml -k  curl --path /api/v0/staged/vm_extensions/web-lb-security-groups -x PUT -d \
      '{"name": "web-lb-security-groups", "cloud_properties": { "security_groups": ["web_lb_security_group", "vms_security_group"] }}'
      
Status: 200 OK

om -e env.yml -k curl --path /api/v0/staged/vm_extensions/ssh-lb-security-groups -x PUT -d \
      '{"name": "ssh-lb-security-groups", "cloud_properties": { "security_groups": ["ssh_lb_security_group", "vms_security_group"] }}'

om -e env.yml -k curl --path /api/v0/staged/vm_extensions/tcp-lb-security-groups -x PUT -d \
      '{"name": "tcp-lb-security-groups", "cloud_properties": { "security_groups": ["tcp_lb_security_group", "vms_security_group"] }}'
```


## Set lb config to TAS tile

#### check terraform output 
example for `awstest` environment
``` bash
$ terraform output web_target_groups

awstest-web-tg-80,
awstest-web-tg-443

$ terraform output ssh_target_groups
awstest-ssh-tg

$ terraform output tcp_target_groups
awstest-tcp-tg-1024
...    

```
#### edit platform-automation-template/awstest/products/tas.yml
- (only if manually setting up) guide
> https://docs.pivotal.io/platform/application-service/2-9/operating/configure-lb.html#aws-terraform
- example for `awstest` environment


```
om -e env.yml staged-config -p cf  > cf.yml
```

```
## om -e env.yml staged-config -p cf  -r false  -c true > cf.yml
```
vi cf.yml

``` yaml
...

diego_brain:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - ssh-lb-security-groups
    elb_names:
    - alb:awstest-ssh-tg
    instance_type:
      id: automatic
    instances: 1
    internet_connected: false
    swap_as_percent_of_memory_size: automatic

router:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - web-lb-security-groups
    elb_names:
    - alb:awstest-web-tg-80
    - alb:awstest-web-tg-443
    instance_type:
      id: automatic
    instances: 1
    internet_connected: false
    swap_as_percent_of_memory_size: automatic

tcp_router:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: 
    - tcp-lb-security-groups
    elb_names:
    - alb:awstest-tcp-tg-1024
    - alb:awstest-tcp-tg-1025
    - alb:awstest-tcp-tg-1026
    - alb:awstest-tcp-tg-1027
    - alb:awstest-tcp-tg-1028
```

configure  director config in opsman VM.
```
om -e env.yml   configure-product -c cf.yml
```
```
configuring cf ...
```
then apply TAS change. 

now gorouter vm should be registered to web-lb target group automatically. diego-brain vm  to ssh-lb.


