
# How to setup concourse pipeline for installing/upgrading PAS tile
- official guide: https://docs.pivotal.io/platform-automation/v4.3/pipelines/multiple-products.html

## prerequisits
- [prepare concourse cluster with credhub](/concourse-with-credhub.md)
- [get pipeline template](/platform-automation/get-pipeline-template.md)
- [download depencencies](/platform-automation/download_dependencies.md)
- [set credhub variables](/platform-automation/set-credhub-variables.md)
- [install opsmanager](/platform-automation/install_opsman.md)

## prepare pipeline parameters
- pipeline parameters should be set to concourse-credhub or set directly to pipeline.
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html
- [sample configs template](https://github.com/myminseok/platform-automation-configs-template)

#### prepare params.yml for `fly set-pipeline`
- platform-automation-configuration/awstest/pipeline-vars/params.yml
- [sample code](https://github.com/myminseok/platform-automation-configuration-template/blob/master/dev/pipeline-vars/params.yml)

#### platform-automation-configuration/awstest/products/versions.yml

#### platform-automation-configuration/awstest/opsman/env.yml

#### create platform-automation-configuration/awstest/products/tas.yml
- how to generate : https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/creating-a-product-config-file.html
- steps:
1. install opsman vm
2. upload TAS tile to opsman: manually or use concourse pipeline
3. setup TAS and apply change.
4. use om cli 'staged-config' or run 'generate-staged-config' in concourse pipeline:  
  - run with set SUBSTITUTE_CREDENTIALS_WITH_PLACEHOLDERS: true in pipeline.
  - will generate  generated-config/cf.yml in configuration git repository
4. copy generated-config/tas.yml to products/tas.yml
5. set PLACEHOLDER value to concourse CREDHUB.
  - use domain.crt and domain.key file in previous steps.
> https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/set-credhub-variables.md

#### (optional) platform-automation-configuration/awstest/vars/tas.yml
- for non-secret params can be set to yml file in vars folder. and will be used in 'prepare-tasks-with-secrets' tasks in concourse pipeline. https://docs.pivotal.io/platform-automation/v4.3/tasks.html#prepare-tasks-with-secrets
#### (optional) credhub 
- add additional secrets : https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/set-credhub-variables.md
- for example tas.yml
``` yaml
region: ap-northeast-2
```

#### configure lb for opsman, director, tas tile.
- [guide](/platform-automation/configure-lb.md)


## How to deploy concourse pipeline
- each foundation will set pipeline using per foundation configs from platform-automation-configuration. for example, pipeline for awstest can be set as following:
- [sample code manage-products-awstest.sh](https://github.com/myminseok/platform-automation-pipelines-template/manage-products-awstest.sh)

``` bash
$ fly -t <FLY-TARGET> login -c https://your.concourse/ -b -k

$ platform-automation-pipelines/manage-products.sh <FLY-TARGET> <FOUNDATION>

$ manage-products.sh demo awstest

```






