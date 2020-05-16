
# (only public cloud) configure LB setting to opsman, director, TAS

#### guide: https://docs.pivotal.io/platform/application-service/2-9/operating/configure-lb.html
####  prepare env.yml: https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/configuring-env.html
####  download om linux cli: https://github.com/pivotal-cf/om/releases
#### set vm_extensions to ops manager
https://github.com/pivotal-cf/terraforming-aws/blob/master/ci/tasks/custom-vm-extensions.sh
```
om -e env.yml -k  curl --path /api/v0/staged/vm_extensions/web-lb-security-groups -x PUT -d \
      '{"name": "web-lb-security-groups", "cloud_properties": { "security_groups": ["web_lb_security_group", "vms_security_group"] }}'
Status: 200 OK

om -e env.yml -k curl --path /api/v0/staged/vm_extensions/ssh-lb-security-groups -x PUT -d \
      '{"name": "ssh-lb-security-groups", "cloud_properties": { "security_groups": ["ssh_lb_security_group", "vms_security_group"] }}'

om -e env.yml -k curl --path /api/v0/staged/vm_extensions/tcp-lb-security-groups -x PUT -d \
      '{"name": "tcp-lb-security-groups", "cloud_properties": { "security_groups": ["tcp_lb_security_group", "vms_security_group"] }}'
```

##  edit platform-automation-configuration/awstest/opsman/director.yml > vmextensions-configuration

```
az-configuration:
- name: ap-northeast-2a

... 

vmextensions-configuration:
- name: web-lb-security-groups
  cloud_properties:
    security_groups:
    - web_lb_security_group
    - vms_security_group
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

## edit  platform-automation-configuration/awstest/products/tas.yml
#### check terraform output 
```
$ terraform output web_target_groups

awstest-web-tg-80,
awstest-web-tg-443

$ terraform output ssh_target_groups
awstest-ssh-tg

$ terraform output tcp_target_groups
awstest-tcp-tg-1024
...    

```
#### edit platform-automation-configuration/awstest/products/tas.yml
- (only if manually setting up) guilde https://docs.pivotal.io/platform/application-service/2-9/operating/configure-lb.html#aws-terraform

```
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
    - alb:awstest-tcp-tg-1029
    - alb:awstest-tcp-tg-1030
    - alb:awstest-tcp-tg-1031
    - alb:awstest-tcp-tg-1032
    - alb:awstest-tcp-tg-1033
```

