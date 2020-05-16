# Setting up installing/upgrading ops-manager concourse pipeline
- official guide
> https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/installing-opsman.html

## prerequisits
- [prepare concourse cluster with credhub](/concourse-with-credhub.md)
- [get pipeline template](/platform-automation/get-pipeline-template.md)
- [set credhub variables](/platform-automation/set-credhub-variables.md)
- [download depencencies](/platform-automation/download_dependencies.md)

## prepare pipeline parameters
- pipeline parameters should be set to concourse-credhub or set directly to pipeline.
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html
- [sample configs template](https://github.com/myminseok/platform-automation-configs-template)

#### prepare params.yml for `fly set-pipeline`
- values in params.yml can be referenced from credhub. see [set credhub variables](/platform-automation/set-credhub-variables.md)
- platform-automation-configuration/awstest/pipeline-vars/params.yml
- [sample code](https://github.com/myminseok/platform-automation-configuration-template/blob/master/dev/pipeline-vars/params.yml)

#### platform-automation-configuration/awstest/opsman/env.yml
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#env
- This file contains properties for targeting and logging into the Ops Manager API. 

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

#### platform-automation-configuration/awstest/opsman/env.yml

#### platform-automation-configuration/awstest/products/versions.yml
- pipeline will download binaries to container in concourse worker VM.
- for vsphere from private s3.
``` yaml
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
``` yaml
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
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#opsmanyml
- how to: https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/installing-opsman.html

``` yaml
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
- official guide: https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/configuring-auth.html

#### platform-automation-configuration/awstest/opsman/director.yml
- official guide: https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/creating-a-director-config-file.html

- generated director.yml need to fix as following:
``` yaml
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
 
 
#### (optional) platform-automation-configuration/awstest/vars/director.yml
- for non-secret params can be set to yml file in vars folder. and can be set to 'prepare-tasks-with-secrets' tasks in concourse pipeline with `VARS_PATHS`.  https://docs.pivotal.io/platform-automation/v4.3/tasks.html#prepare-tasks-with-secrets. example for vars/director.yml
``` yaml
region: ap-northeast-2
```
- WARNING: any params referencing to credhub should not be set to files in vars folder, but set to products config file(ie. products/director.yml). because 'prepare-tasks-with-secrets' tasks will use vars file specified in `VARS_PATHS` directly, without referencing to credhub. those parameters should be set . (see https://docs.pivotal.io/platform-automation/v4.3/tasks.html#prepare-tasks-with-secrets)
- for example, following params in vars/director.yml will fail when running pipeline in 'prepare-tasks-with-secrets' task. example for vars/director.yml
``` yaml
pivnet_token: ((pivnet_token_in_credhub))
```
#### (optional) platform-automation-configuration/awstest/vars/opsman.yml
- the same as above.

##  Set secrets to concourse credhub per each foundation
####  login to credhub
``` bash
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat login-credhub.sh
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://credhub.pcfdemo.net:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)

```
#### set secrets example.
- platform-automation-configuration/awstest/pipeline-vars/set-credhub.sh
- platform-automation-configuration/awstest/pipeline-vars/set-credhub-from-terraform.sh
- https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/set-credhub-variables.md


## How to deploy concourse pipeline
- each foundation will set pipeline using per foundation configs from platform-automation-configuration. for example, pipeline for awstest can be set as following:
- [sample code manage-products-awstest.sh](https://github.com/myminseok/platform-automation-pipelines-template/manage-products-awstest.sh)

``` bash
$ fly -t <FLY-TARGET> login -c https://your.concourse/ -b -k

$ platform-automation-pipelines/manage-products.sh <FLY-TARGET> <FOUNDATION>

$ manage-products.sh demo awstest

```

# patch/upgrade opsman
- (optional) download product to local s3.
- run `upgrade-opsman` job1 in pipeline
- `upgrade-opsman` should generate director.yml to platform-automation-configuration>FOUNDATION>generated-config>opsman.yml

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
``` json
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




