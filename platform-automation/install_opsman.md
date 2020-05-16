# How to setup concourse pipeline for installing/upgrading ops-manager
- https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/installing-opsman.html

## prerequisits
- get pipeline:
> https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/get-template.md
- download depencencies:
> https://github.com/myminseok/pivotal-docs/edit/master/platform-automation/download_dependencies.md

## configure set-pipeline variables
- docs: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-configs-template
    
#### platform-automation-configuration/awstest/pipeline-vars/params.yml
referencing parameters should be set to concourse-credhub or set directly to pipeline.
```
foundation: awstest

s3:
  endpoint: https://s3.ap-northeast-2.amazonaws.com
  access_key_id: ((aws_access_key_id))
  secret_access_key: ((aws_secret_access_key))
  region_name: "ap-northeast-2"
  buckets:
    platform_automation: awstest-platform-automation
    pivnet_products: awstest-pivnet-products

git:
  platform_automation_pipelines:
    uri: git@github.com:myminseok/platform-automation-pipelines-template.git
    branch: master
  platform_automation_configs:
    uri: git@github.com:myminseok/platform-automation-configuration-template.git
    branch: master
  user:
    email: ((git_user_email))
    username: "Platform Automation Bot"
  private_key: ((git_private_key.private_key))

credhub:
  server: https://192.168.50.1:9000
  ##ca_cert: ((credhub_ca_cert.certificate))
  client: ((credhub_client.username))
  secret: ((credhub_client.password))

pivnet:
  token: ((pivnet_token))

```
> - aws_access_key_id: set to concourse-credhub or set directly to pipeline.
  - aws_secret_access_key: set to concourse-credhub or set directly to pipeline.

#### platform-automation-configuration/awstest/opsman/env.yml
- https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#env

This file contains properties for targeting and logging into the Ops Manager API. 

```
---
target: ((opsman_target))
connect-timeout: 30                 # default 5
request-timeout: 3600               # default 1800
skip-ssl-validation: true           # default false
username: ((opsman_admin.username))
password: ((opsman_admin.password))
decryption-passphrase: ((decryption-passphrase))
```

#### platform-automation-configuration/awstest/opsman/env.yml

#### platform-automation-configuration/awstest/products/versions.yml
- pipeline will download binaries to container in concourse worker VM.
- for vsphere from private s3.
```
products:
  opsman:
    product-version: "2.9.1"
    pivnet-product-slug: ops-manager
    pivnet-file-glob: "*.ova"
    download-stemcell: "false"
    s3-endpoint: http://10.10.10.199:9000
    s3-region-name: "dummy"
    s3-bucket: "pivnet-products"
    s3-disable-ssl: "true"
    s3-access-key-id: ((s3_access_key_id))
    s3-secret-access-key: ((s3_secret_access_key))
    pivnet-api-token: ((pivnet_token))
  tas:
    product-version: "2.9.2"
    pivnet-product-slug: ops-manager
    pivnet-file-glob: "cf*.pivotal"
    download-stemcell: "false"
    s3-endpoint: http://10.10.10.199:9000
    s3-region-name: "dummy"
    s3-bucket: "pivnet-products"
    s3-disable-ssl: "true"
    s3-access-key-id: ((s3_access_key_id))
    s3-secret-access-key: ((s3_secret_access_key))
    pivnet-api-token: ((pivnet_token))
```
- for aws from pivnet.
```
products:
  opsman:
    product-version: "2.9.1"
    pivnet-product-slug: ops-manager
    pivnet-file-glob: "ops-manager-aws*.yml"
    download-stemcell: "false"
    pivnet-api-token: ((pivnet_token))

  tas:
    product-version: "2.9.2"
    pivnet-product-slug: elastic-runtime
    pivnet-file-glob: "cf*.pivotal"
    stemcell-iaas: aws
    pivnet-api-token: ((pivnet_token))

```

#### platform-automation-configuration/awstest/opsman/opsman.yml
- https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#opsmanyml
- https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/installing-opsman.html

```
---
## 2.9.1
opsman-configuration:
  aws:
    region: ap-northeast-2
    vpc_subnet_id: ((public_subnet_ids)) ## terraform module.infra.public_subnet_ids, 0
    security_group_ids: [ ((ops_manager_security_group_id)) ]
    key_pair_name: ((ops_manager_ssh_public_key_name))  # used to ssh to VM
    iam_instance_profile_name: ((ops_manager_iam_instance_profile_name))
    public_ip: ((ops_manager_public_ip))      # Reserved Elastic IP
    # private_ip: 10.0.0.2
    # vm_name: ops-manager-vm    # default - ops-manager-vm
    # boot_disk_size: 100        # default - 200 (GB)
    instance_type: m5.large    # default - m5.large
    access_key_id: ((aws_access_key_id)) ## not ops_manager_iam_user_access_key
    secret_access_key: ((aws_secret_access_key))
```
#### platform-automation-configuration/awstest/opsman/auth.yml
- https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/configuring-auth.html

#### platform-automation-configuration/awstest/opsman/director.yml
- https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/creating-a-director-config-file.html

- generated director.yml need to fix as following:
```
## add vcenter_password

iaas-configurations:
  - additional_cloud_properties: {}
  ...
    vcenter_username: 
    vcenter_password: 
  ...

## modify encryption
properties-configuration:
  director_configuration:
  ...
    #encryption: []
    encryption:
      keys: []
      providers: []
  ...
  #dns_configuration: []
  dns_configuration:
    excluded_recursors: []
    handlers: []
 ```

  3. configure director tile manually.
  4. apply-director-change
  5. generate-staged-director-config > configure-director
 
 
#### platform-automation-configuration/awstest/vars/director.yml
- for non-secret params can be set to yml file in vars folder. and will be used in 'prepare-tasks-with-secrets' tasks in concourse pipeline. https://docs.pivotal.io/platform-automation/v4.3/tasks.html#prepare-tasks-with-secrets

for example opsman.yml
```
region: ap-northeast-2
```



##  Set secrets to concourse credhub per each foundation
####  login to credhub
```
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat login-credhub.sh
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://credhub.pcfdemo.net:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)

```
#### set secrets example.
refer to:
- platform-automation-configuration/awstest/pipeline-vars/set-credhub.sh
- platform-automation-configuration/awstest/pipeline-vars/set-credhub-from-terraform.sh

```

credhub set -t value -n /concourse/main/s3_access_key_id -v admin
credhub set -t value -n /concourse/main/s3_secret_access_key -v "PASSWORD"
credhub set -t value -n /concourse/main/pivnet_token -v 11111111

credhub set -t value -n /concourse/main/git_user_email -v admin@user.io
credhub set -t value -n /concourse/main/git_user_username -v admin

credhub set -t user -n /concourse/main/vcenter_user -z admin@vcenter.local -w "PASSWORD"
credhub set -t ssh -n /concourse/main/opsman_ssh_key -u ~/.ssh/id_rsa.pub -p ~/.ssh/id_rsa
credhub set -t value  -n /concourse/main/opsman_ssh_password  -v "PASSWORD"

# register ssh key for git. ex) ~/.ssh/id_rsa
credhub set -t rsa  -n /concourse/main/git_private_key  -p ~/.ssh/id_rsa
 
# cd concourse-bosh-deployment/cluster
# bosh int ./concourse-creds.yml --path /atc_tls/certificate > atc_tls.cert
# bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub set -t certificate -n /concourse/main/credhub_ca_cert -c ./credhub-ca.ca

# grep concourse_to_credhub ./concourse-creds.yml
credhub set -t user -n /concourse/main/credhub_client -z concourse_client -w "PASSWORD"

credhub set -t user  -n /concourse/main/opsman_admin -z admin -w "PASSWORD"
credhub set -t value -n /concourse/main/decryption-passphrase -v "PASSWORD"
credhub set -t value -n /concourse/main/opsman_target -v https://opsman_url

```

## how to deploy concourse pipeline

each foundation will set pipeline using per foundation configs from platform-automation-configuration. for example, pipeline for awstest can be set as following:

```
$ fly -t <FLY-TARGET> login -c https://your.concourse/ -b -k

$ platform-automation-pipelines/manage-products-awstest.sh <FLY-TARGET>

```

-  manage-products-awstest.sh
```
#!/bin/bash

if [ -z $1 ]  ; then
    echo "please provide parameters"
	echo "${BASH_SOURCE[0]} [fly-target]"
	exit
fi

FLY_TARGET=$1

fly -t ${FLY_TARGET} sp -p "awstest-manage-products" \
-c ./manage-products.yml \
-l ../platform-automation-configuration-template/awstest/pipeline-vars/params.yml

```


#### how to run pipeline for minor upgrade opsman  
  1. upgrade-opsman-vm
  2. configure director tile manually.
  3. apply-director-change
  4. generate-staged-director-config > configure-director

#### how to  run pipeline for patching opsman
  1. download opsman ova from pivnet and upload to s3 as following
  2. edit version info in products.yml from git and commit.
  3. then the 'replace-opsman-vm' job in the pipeline will automatically be triggered

### how to  run pipeline for recovering opsman
  1. download opsman ova from pivnet and upload to s3 as following
  2. edit version info in products.yml from git and commit.
  3. create-new-opsman-vm
  4. import-installation
  5. apply-director-change
  then opsman will be recovered in a few minitues.

## advanced.
#### bosh dns config for a private DNS.
opsmanager UI.>BOSH Director > BOSH DNS config
```
[
  {
    "cache": {
      "enabled": false
    },
    "domain": "example.com",
    "source": {
      "recursors": ["PRIVATE_DNS_IP:53"],
      "type": "dns"
    }
  }
]
```
https://learn.hashicorp.com/consul/cloud-integrations/consul-pcf




