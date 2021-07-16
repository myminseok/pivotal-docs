
# (Only for public cloud) configure LB setting to opsman, director, TAS


## official guide
- https://docs.pivotal.io/platform/application-service/2-9/operating/configure-lb.html
- https://docs.pivotal.io/ops-manager/2-10/aws/prepare-env-terraform.html
- [platform-automation/terraforming-aws.md](terraforming-aws.md)

### terraforming on aws
#### use https://github.com/pivotal/paving 

```
git clone https://github.com/pivotal/paving
cd aws
rm -rf pks-*
cp terraform.tfvars.example terraform.tfvars 
```

####  edit paving/aws/terraform.tfvars
```vi paving/aws/terraform.tfvars
environment_name = "mkim-tas"

access_key = "ACCESS_KEY"
secret_key = "SECRET_KEY"

region = "ap-northeast-2"
availability_zones = ["ap-northeast-2a","ap-northeast-2b","ap-northeast-2c"]

hosted_zone = "pcfdemo.net."
```
#### terraforming for LB, DNS, security groups
```
cd paving/aws
terraform init
terraform plan -var-file terraform.tfvars
terraform apply -var-file terraform.tfvars
terraform output stable_config_opsmanager

# terraform destroy -var-file terraform.tfvars

```
#### extract opsman ssh private key
```
## copy ops_manager_ssh_private_key value 
terraform output stable_config_opsmanager


## convert RSA key format. 
### !!! make sure starting quote and ending quote with NO backslash '\'

printf -- "-----BEGIN RSA PRIVATE KEY-----\\nMIIJKQIBAAKCAgEA0MlZIK59WUoZzquwzun+IB
....
+sOr+LLfOb5mjwZvbL9scdy1YqVNM\\n-----END RSA PRIVATE KEY-----\\n"  > opsman.key


### 
chmod 600 opsman.key

```
#### (WARNING!!! ) change opsmanager security group > inbound rule to myIP from ALL
- AWS console> EC2> security groups

#### create opsman VM
- network.pivotal.io.  check opsmanager AMI ID for your AWS region
- create opsman vm on public network which is created by paving.
- access opsman via opsman domain which is created by paving. https://opsmanager.mkim-tas.pcfdemo.net

#### ssh into opsman VM
```
chmod 600 opsman.key 
ssh -i opsman.key ubuntu@opsmanager.mkim-tas.pcfdemo.net

```
####  create env.yml
- https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/configuring-env.html


####  download om linux cli
- https://github.com/pivotal-cf/om/releases


#### set vm_extensions 
set vm_extension one of opsmanager API or director.yml
- https://github.com/pivotal-cf/terraforming-aws/blob/master/ci/tasks/custom-vm-extensions.sh


##### OPTION 1)set vm_extensions director.yml 
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
configure  director config in opsman VM.
```
om -e env.yml configure-director -c director.yml

```

##### OPTION 2)set vm_extensions to opsman API 

``` bash
om -e env.yml -k  curl --path /api/v0/staged/vm_extensions/web-lb-security-groups -x PUT -d \
      '{"name": "web-lb-security-groups", "cloud_properties": { "security_groups": ["web_lb_security_group", "vms_security_group"] }}'
Status: 200 OK

om -e env.yml -k curl --path /api/v0/staged/vm_extensions/ssh-lb-security-groups -x PUT -d \
      '{"name": "ssh-lb-security-groups", "cloud_properties": { "security_groups": ["ssh_lb_security_group", "vms_security_group"] }}'

om -e env.yml -k curl --path /api/v0/staged/vm_extensions/tcp-lb-security-groups -x PUT -d \
      '{"name": "tcp-lb-security-groups", "cloud_properties": { "security_groups": ["tcp_lb_security_group", "vms_security_group"] }}'
```



## set lb config to  TAS tile

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
om -e env.yml staged-config -p cf  -c true -r false > cf.yml
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
    - alb:awstest-tcp-tg-1029
    - alb:awstest-tcp-tg-1030
    - alb:awstest-tcp-tg-1031
    - alb:awstest-tcp-tg-1032
    - alb:awstest-tcp-tg-1033
```

configure  director config in opsman VM.
```
om -e env.yml   configure-product -c cf.yml

```
then apply TAS change. gorouter vm should be registered to web-lb target group automatically. diego-brain vm  to ssh-lb.
