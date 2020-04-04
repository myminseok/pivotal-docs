
# How to setup concourse pipeline for downloading dependencies
- https://docs.pivotal.io/platform-automation/v4.3/pipelines/resources.html

## Get pipeline template
in jumpbox,as ubuntu user
```
mkdir platform-automation-workspace
cd platform-automation-workspace

git clone https://github.com/myminseok/platform-automation-pipelines-template   platform-automation-pipelines
git clone https://github.com/myminseok/platform-automation-configuration-template   platform-automation-configuration
```

## Set pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template
```
platform-automation-pipelines
├── download-product.sh
├── download-product.yml

```

make sure to point `platform-automation-configuration` folder in the download-product.sh
```
platform-automation-pipelines> vi download-product.sh
#!/bin/bash

...

fly -t ${FLY_TARGET} sp -p "download-product" \
-c ./download-product.yml \
-l ../platform-automation-configuration/${FLY_TARGET}/pipeline-vars/common-params.yml \
-v foundation=${FLY_TARGET}

```


## Set pipeline variables
per each foundation, pipeline variables is defined
- sample: https://github.com/myminseok/platform-automation-configuration-template

```
platform-automation-configuration
└── dev
    ├── config
    ├── download-product-configs
    │   ├── healthwatch.yml
    │   ├── opsman.yml
    │   └── pas.yml
    └── pipeline-vars
       └── common-params.yml

```

opsman.yml
```
---
pivnet-api-token: ((pivnet_token))
pivnet-file-glob: "*vsphere*.ova"
pivnet-product-slug: ops-manager
product-version-regex: ^2\.4\..*$

```

pas.yml
```
---
pivnet-api-token: ((pivnet_token))
pivnet-file-glob: "cf-*.pivotal"
pivnet-product-slug: elastic-runtime
product-version-regex: ^2\.4\..*$
stemcell-iaas: vsphere

```


###  Set Pipeline secrets to concourse credhub  per each foundation
in ssh terminal, login to credhub
```
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat login-credhub.sh
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://credhub.pcfdemo.net:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)

```
set  per each foundation, `dev` for this case 
```
## /concourse/dev
credhub set -t value -n /concourse/dev/s3_access_key_id -v <S3_ACCESS_KEY>
credhub set -t value -n /concourse/dev/s3_secret_access_key -v "<S3_SECRET>"
credhub set -t value -n /concourse/dev/pivnet_token -v <YOUR_PIVNET_TOKEN>

credhub set -t value -n /concourse/dev/git_user_email -v <GIT_USER_EMAIL>
credhub set -t value -n /concourse/dev/git_user_username -v <GIT_USER_NAME>

credhub set -t user -n /concourse/dev/vcenter_user -z <user> -w <password>

# register ssh key for git. ex) ~/.ssh/id_rsa
credhub set -t rsa  -n /concourse/dev/git_private_key  -p ~/.ssh/id_rsa 
 
cd concourse-bosh-deployment/cluster
# bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub set -t certificate -n /concourse/dev/credhub_ca_cert -c ./credhub-ca.ca

# grep concourse_to_credhub ./concourse-creds.yml
credhub set -t user -n /concourse/dev/credhub_client -z concourse_client -w <concourse_to_credhub>

credhub set -t user  -n /concourse/dev/opsman_admin -z admin -w <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev/decryption-passphrase -v <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev/opsman_target -v https://opsman_url_or_IP

```

## Parepare s3 
download platform-automation-image, platform-automation-image-tasks from network.pivotal.io to s3

```
|-- pivnet-products

`-- platform-automation
    |-- platform-automation-image-2.1.1-beta.1.tgz
    `-- platform-automation-tasks-2.1.1-beta.1.zip
```


## how to deploy pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template

```
$ cd platform-automation-workspace
$ ls -al
platform-automation-configuration
platform-automation-pipelines

$ cd platform-automation-pipelines

$ fly -t <foundaton> login -c https://your.concourse/ -b -k

$ ./download-product.h <foundaton>
```
> - foundation: name of pcf foundation in platform-automation-config git.  
> - this will use platform-automation-configuration/<foundaton>/pipeline-vars/common-params.yml
> - will use commons platform-automation-configuration
> - this will create a concourse pipeline named '<foundation>-opsman-install-upgrade'


# Result in S3 
```
|-- pivnet-products
|   |-- cf-2.4.5-build.25.pivotal
|   |-- healthwatch-stemcell
|   |   `-- bosh-stemcell-97.71-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |-- pas-stemcell
|   |   |-- bosh-stemcell-170.45-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |   `-- bosh-stemcell-170.48-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |-- pcf-vsphere-2.4-build.171.ova
|   `-- p-healthwatch-1.4.5-build.41.pivotal
`-- platform-automation
    |-- platform-automation-image-2.1.1-beta.1.tgz
    `-- platform-automation-tasks-2.1.1-beta.1.zip
```


##
`platform-automation-tasks/tasks/download-product.yml` download product and upload to s3 even if there is the same file in s3. for better efficiency, this pipeline uses `semver`. 

```

- name: opsman-product
  type: s3
  source:
    endpoint: ((s3.endpoint))
    access_key_id: ((s3.access_key_id))
    bucket: ((s3.buckets.pivnet_products))
    region_name: ((s3.region_name))
    secret_access_key: ((s3.secret_access_key))
    regexp: "ops-manager-vsphere*.ova"
    skip_ssl_verification: true

#- name: opsman-product-new-version-git
#  type: semver
#  source:
#    driver: git
#    private_key: ((git.private_key))
#    uri: ((git.configuration.uri))
#    branch: master
#    file: ((foundation)/opsman-version
#    initial_version: 0.1.0

- name: opsman-product-new-version-s3.    <=== creates `opsman-version` file in s3 bucket.
  type: semver
  source:
    endpoint: ((s3.endpoint))
    access_key_id: ((s3.access_key_id))
    bucket: ((s3.buckets.pivnet_products))
    region_name: ((s3.region_name))
    secret_access_key: ((s3.secret_access_key))
    skip_ssl_verification: true
    key: opsman-version
    initial_version: 0.1.0
    

jobs:
  
- name: pre-fetch-opsman
  plan:
  - in_parallel:
    - get: platform-automation-pipelines
    - get: platform-automation-image
      params: { unpack: true }
    - get: platform-automation-tasks
      params: { unpack: true }
    - get: configuration
    - get: opsman-product-new-version-s3   <=== prepare bump up locally.
      params: {bump: minor}
  - task: credhub-interpolate
    <<: *credhub-interpolate
  - task: download-only-opsman-image
    image: platform-automation-image
    file: platform-automation-pipelines/tasks/download-only-product.yml  <=== download product from pivnet into worker VM
    input_mapping: {config: configuration }
    params:
      CONFIG_FILE: ((foundation))/download-product-configs/opsman.yml
    on_success:
      try:   <===  `try` will ignore task error. so the pipeline can continues.
        task: check_dup_file_in_s3
        image: platform-automation-image
        file: platform-automation-pipelines/tasks/exists_file_s3.yml. <=== `check_dup_file_in_s3` task will check if the product file exists in s3. if exists, exit 1. if not, it will bump up semver. 
        input_mapping: {downloaded-product: downloaded-product }
        params:
          endpoint: ((s3.endpoint))
          access_key_id: ((s3.access_key_id))
          bucket: ((s3.buckets.pivnet_products))
          region_name: ((s3.region_name))
          secret_access_key: ((s3.secret_access_key))
        on_success:
          try:
            put: opsman-product-new-version-s3
            params: {file: opsman-product-new-version-s3/number}

- name: fetch-opsman
  plan:
  - in_parallel:
    - get: platform-automation-pipelines
    - get: platform-automation-image
      params: { unpack: true }
    - get: platform-automation-tasks
      params: { unpack: true }
    - get: configuration
    - get: opsman-product-new-version-s3  <=== this job will be triggered by bumped up `semver`.
      trigger: true
  - task: credhub-interpolate
    <<: *credhub-interpolate
  - task: download-opsman-image
    image: platform-automation-image
    file: platform-automation-tasks/tasks/download-product.yml
    input_mapping: {config: configuration }
    params:
      CONFIG_FILE: ((foundation))/download-product-configs/opsman.yml
  - put: opsman-product
    params:
      file: downloaded-product/*

```


