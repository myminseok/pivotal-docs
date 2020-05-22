
# Setting up Installing/Patching/Upgrading TAS tile with Concourse pipeline
- official guide
> https://docs.pivotal.io/platform-automation/v4.3/pipelines/multiple-products.html

## Prerequisits
- [prepare concourse cluster with credhub](/concourse-with-credhub.md)
- [get pipeline template](/platform-automation/get-pipeline-template.md)
- [download depencencies](/platform-automation/download_dependencies.md)
- [set credhub variables](/platform-automation/set-credhub-variables.md)
- [install opsmanager](/platform-automation/install_opsman.md)

## Prepare pipeline parameters
- pipeline parameters should be set to concourse-credhub or set directly to pipeline.
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html
- [sample configs template](https://github.com/myminseok/platform-automation-configs-template)

#### Prepare params.yml for `fly set-pipeline`
- [platform-automation-configuration/awstest/pipeline-vars/params.yml](https://github.com/myminseok/platform-automation-configuration-template/blob/master/awstest/pipeline-vars/params.yml)
- values in params.yml can be referenced from credhub. see [set credhub variables](/platform-automation/set-credhub-variables.md)

#### platform-automation-configuration/awstest/opsman/env.yml
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#env
- This file contains properties for targeting and logging into the Ops Manager API. 
- [platform-automation-configuration/awstest/opsman/env.yml](https://github.com/myminseok/platform-automation-configuration-template/blob/master/awstest/opsman/env.yml)

#### platform-automation-configuration/awstest/products/versions.yml
- pipeline will download binaries to container in concourse worker VM.
- [platform-automation-configuration/awstest/products/versions.yml](https://github.com/myminseok/platform-automation-configuration-template/blob/master/awstest/products/versions.yml)

#### Create platform-automation-configuration/awstest/products/tas.yml
- how to generate: https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/creating-a-product-config-file.html
- [platform-automation-configuration/awstest/products/tas.yml](https://github.com/myminseok/platform-automation-configuration-template/blob/master/awstest/products/tas.yml)

1. install opsman vm
2. upload TAS tile to opsman: manually or use concourse pipeline
3. setup TAS and apply change.

4. use om cli 'staged-config' or run 'generate-staged-config' in concourse pipeline:  
>  - run with set SUBSTITUTE_CREDENTIALS_WITH_PLACEHOLDERS: true in pipeline.
>  - will generate  generated-config/cf.yml in configuration git repository
5. copy generated-config/tas.yml to products/tas.yml
6. set PLACEHOLDER value to concourse CREDHUB.
>  - use domain.crt and domain.key file in previous steps.
> https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/set-credhub-variables.md

#### using self-signed domain on TAS
1. copy the self-signed certifiate from Opsman UI> TAS tile> networking> "Certificates and private keys for the Gorouter and HAProxy"> certificate 
2. paste the certificate into Opsman UI > bosh director tile > security> Trusted Certificates https://docs.pivotal.io/platform/ops-manager/2-9/aws/config-manual.html#security
3. apply change director and TAS 

#### using self-signed domain for Service tile 
- copy the self-signed certifiate from bosh credhub https://docs.pivotal.io/rabbitmq-cf/1-19/prepare-tls.html
```
credhub get \
   --name=/services/tls_ca \
   -k ca
```   
2. put the certificate on Opsman UI > bosh director tile > security> Trusted Certificates https://docs.pivotal.io/platform/ops-manager/2-9/aws/config-manual.html#security
3. apply change director and TAS 





#### (optional) platform-automation-configuration/awstest/vars/tas.yml
- for non-secret params can be set to yml file in vars folder. and can be set to 'prepare-tasks-with-secrets' tasks in concourse pipeline with `VARS_PATHS`.  https://docs.pivotal.io/platform-automation/v4.3/tasks.html#prepare-tasks-with-secrets. example for vars/tas.yml
``` yaml
region: ap-northeast-2
```
- WARNING: any params referencing to credhub should not be set to files in vars folder, but set to products config file(ie. products/tas.yml). because 'prepare-tasks-with-secrets' tasks will use vars file specified in `VARS_PATHS` directly, without referencing to credhub. those parameters should be set . (see https://docs.pivotal.io/platform-automation/v4.3/tasks.html#prepare-tasks-with-secrets)
- for example, following params in vars/director.yml will fail when running pipeline in 'prepare-tasks-with-secrets' task. example for vars/tas.yml
``` yaml
pivnet_token: ((pivnet_token_in_credhub))
```


#### Configure LoadBalancer setting to opsman, director, tas tile.
- [guide](/platform-automation/configure-lb.md)


## Deploy concourse pipeline
- each foundation will set pipeline using per foundation configs from platform-automation-configuration. for example, pipeline for awstest can be set as following:
- [sample code manage-products-awstest.sh](https://github.com/myminseok/platform-automation-pipelines-template/manage-products-awstest.sh)

``` bash
$ fly -t <FLY-TARGET> login -c https://your.concourse/ -b -k

$ platform-automation-pipelines/manage-products.sh <FLY-TARGET> <FOUNDATION>

$ manage-products.sh demo awstest

```
