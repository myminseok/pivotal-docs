
# Setting up Downloading Dependencies with Concourse pipeline
- official guide
> https://docs.pivotal.io/platform-automation/v4.3/pipelines/resources.html

## Prerequisits
- [prepare concourse cluster with credhub](/concourse-with-credhub.md)
- [get pipeline template](/platform-automation/get-pipeline-template.md)

## Prepare pipeline parameters
- pipeline parameters should be set to concourse-credhub or set directly to pipeline.
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html
- [sample configs template](https://github.com/myminseok/platform-automation-configs-template)

#### Prepare params.yml for `fly set-pipeline`
- values in params.yml can be referenced from credhub. see [set credhub variables](/platform-automation/set-credhub-variables.md)
- platform-automation-template/awstest/pipeline-vars/params.yml
- [sample code](https://github.com/myminseok/platform-automation-template/blob/master/dev/pipeline-vars/params.yml)

``` yaml
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
    uri: git@github.com:myminseok/platform-automation-template.git
    branch: master
  platform_automation_configs:
    uri: git@github.com:myminseok/platform-automation-template.git
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
> - aws_access_key_id: set to concourse-credhub recommended. [set credhub variables](/platform-automation/set-credhub-variables.md)
> - ...

## Deploy concourse pipeline
- [get pipeline template](/platform-automation/get-pipeline-template.md)
- [pipeline template code](https://github.com/myminseok/platform-automation-template)
``` 
platform-automation-pipelines
├── download-products-dev.sh
├── download-products.sh
├── download-products.yml

```

- each foundation will set pipeline using per foundation configs from platform-automation-configuration. 
- [sample code download-product.sh](https://github.com/myminseok/platform-automation-template/blob/master/download-product.sh)
- for example, download pipeline for `awstest` environment can be set as following:
``` bash
$ fly -t <FLY-TARGET> login -c https://your.concourse/ -b -k

$ platform-automation-pipelines/download-products.sh <FLY-TARGET> <FOUNDATION>

```


# Downloaded files in private S3 
- download product tile and stemcells from pivnet to s3, a file name of '[pivnet-product-slug, product-version]' in s3 bucket.
``` 
|-- pivnet-products
|   |-- [elastic-runtime,2.6.3]cf-2.6.3-build.21.pivotal
|   |-- [stemcells-ubuntu-xenial,250.56]bosh-stemcell-250.56-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |   [stemcells-ubuntu-xenial,97.71]bosh-stemcell-97.71-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |-- [ops-manager,2.9.1]ops-manager-2.9.1-build.171.ova
|   `-- [p-healthwatch,1.4.5]p-healthwatch-1.4.5-build.41.pivotal
`-- platform-automation
    |-- platform-automation-image-4.3.6.tgz
    `-- platform-automation-tasks-4.3.6.zip
```

   

## (optional customizing) For better download and upload efficiency
- `platform-automation-tasks/tasks/download-product.yml` upload to s3 even though there is the same file in s3. 
- for better efficiency, using `semver` can prevent uploading the same binary that is already in s3(tested on non versioned s3)

```yaml

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
    file: platform-automation-pipelines/tasks/download-only-product.yml  <=== if there is new file in pivnet, download the product into worker VM. it will be chached and shared with the next tasks (this worker VM scope)
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
            put: opsman-product-new-version-s3               <=== bump up semver
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

