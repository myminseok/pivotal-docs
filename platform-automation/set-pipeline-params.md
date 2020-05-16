
Each Foundation environment(ops-manager, TAS) will need to have pipeline parameters. and those parameters can be set to concourse-credhub or set directly to pipeline.

####  download credhub cli: 
- https://github.com/cloudfoundry-incubator/credhub-cli/releases

####  login to credhub
``` bash
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat login-credhub.sh
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://credhub.pcfdemo.net:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)

platform-automation-configuration/awstest/pipeline-vars/set-credhub.sh
```

#### set directly to the pipeline when fly set-pipeline
- create a params.yml file(platform-automation-configuration/awstest/pipeline-vars/params.yml)
- [sample params.yml](https://github.com/myminseok/platform-automation-configuration-template/blob/master/dev/pipeline-vars/params.yml)
   
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
>  - aws_secret_access_key: set to concourse-credhub or set directly to pipeline.
