# How to setup concourse pipeline for installing/upgrading opsmanager
- https://docs.pivotal.io/platform-automation/v4.3/how-to-guides/installing-opsman.html

## prerequisits
#### you need to download depencencies
https://github.com/myminseok/pivotal-docs/edit/master/platform-automation/download_dependencies.md


## Get pipeline template
in jumpbox,as ubuntu user
```
mkdir platform-automation-workspace
cd platform-automation-workspace

git clone https://github.com/myminseok/platform-automation-pipelines-template   platform-automation-pipelines
git clone https://github.com/myminseok/platform-automation-configuration-template   platform-automation-configuration
```


## Pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template
```
platform-automation-pipelines:
├── install-upgrade-opsman.sh
├── install-upgrade-opsman.yml
├── tasks
│   ├── apply-product-changes.yml
```

make sure to point `platform-automation-configuration` folder in the download-product.sh
```
platform-automation-pipelines> vi download-product.sh
#!/bin/bash

...

fly -t ${FLY_TARGET} sp -p "${FOUNDATION}-opsman-install-upgrade" \
-c ./install-upgrade-opsman.yml \
-l ../platform-automation-configuration/${FLY_TARGET}/pipeline-vars/common-params.yml \
-v foundation=${FLY_TARGET}

```



## pipeline variables
per each foundation, pipeline variables is defined
```
platform-automation-configuration>
── dev
│   ├── config
│   │   └── auth.yml
│   ├── download-product-configs
│   │   ├── healthwatch.yml
│   │   ├── opsman.yml
│   │   └── pas.yml
│   ├── env
│   │   └── env.yml
│   ├── generated-config
│   │   ├── cf.yml
│   │   └── director.yml
│   ├── pipeline-vars
│   │   └── common-params.yml
│   ├── products
│   │   ├── cf.yml
│   │   ├── ops-manager.yml
│   │   └── director.yml
│   ├── setenv-credhub.sh
│   ├── state
│   │   └── state.yml
```


#### common-params.yml
- docs: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-configuration-template
    
platform-automation-configuration> dev > pipeline-vars > common-params.yml
```
s3:
  endpoint: http://10.10.10.199:9000
  access_key_id: ((s3_access_key_id))
  secret_access_key: ((s3_secret_access_key))
  region_name: ""
  buckets:
    platform_automation: platform-automation
    pivnet_products: pivnet-products
    installation: installation-dev-1
    bbr-backup: bbr-pcfdemo

git:
  platform_automation_pipelines:
   uri: git@github.com:myminseok/platform-automation-pipelines-template.git
  platform_automation_tasks:
    uri: ssh://pivotal@10.10.10.199/platform/platform_automation_tasks.git
  configuration:
    uri: pivotal@10.10.10.199:platform/platform-conf.git
  variable:
    uri: pivotal@10.10.10.199:platform/platform-conf.git
  user: 
    email: user@pivotal.io
    #username: ((git_user.username))
    username: "Platform Automation Bot"
  private_key: ((git_private_key.private_key))

credhub:
  server: https://concourse.pcfdemo.net:8844
  ca_cert: ((credhub_ca_cert.certificate))
  client: ((credhub_client.username))
  secret: ((credhub_client.password))

pivnet: 
  token: ((pivnet_token))
  
```
#### env.yml
- https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#env
```
---

# Env Config
# This file contains properties for targeting and logging into the Ops Manager API.

target: ((opsman_target))
connect-timeout: 30                 # default 5
request-timeout: 3600               # default 1800
skip-ssl-validation: true           # default false
username: ((opsman_admin.username))
password: ((opsman_admin.password))
decryption-passphrase: ((decryption-passphrase))
```
> - ops-manager.yml:   https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html
  - auth.yml : https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html#uaa-authentication
  - director.yml: see bellow.


##   Set Pipeline secrets to concourse credhub  per each foundation
login to credhub
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

## how to deploy pipeline

```
$ fly -t <foundaton> login -c https://your.concourse/ -b -k

$ ./install-upgrade-opsman.sh <foundaton>
```
> - foundation: name of pcf foundation in platform-automation-config git.  
> - will use commons platform-automation-configuration-template
> - this will create a concourse pipeline named '<foundation>-opsman-install-upgrade'

#### how to get opsman.yml template for a new opsman 

  1. create-new-opsman-vm
  2. configure-authentication
  3. generate-staged-config
   - it will extract director config and save to \<foundation>/generated-config/director.yml.
   - copy \<foundation>/generated-config/director.yml to \<foundation>/products/director.yml
   - edit \<foundation>/products/director.yml as following:
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
   - create \<foundation>/vars/director-vars.yml and edit secret key/values which maps to products/director.yml
  3. configure director tile manually.
  4. apply-director-change
  5. generate-staged-director-config > configure-director
 
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
