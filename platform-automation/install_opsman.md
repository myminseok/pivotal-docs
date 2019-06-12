# How to setup concourse pipeline for installing/upgrading PCF opsmanager

## Ref
- http://docs.pivotal.io/platform-automation/v2.1/reference/pipeline.html#installing-ops-manager-and-tiles


## Config
- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-configuration-template
```
platform-automation-configuration-template
└── dev-1
    ├── config
    │   ├── auth.yml    
    │   └── opsman-2.4.yml
    ├── download-product-configs
    ├── env
    │   └── env.yml
    ├── generated-config
    ├── state
    └── vars

```

### env.yml
- http://docs.pivotal.io/platform-automation/v2.1/configuration-management/configure-env.html
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


- opsman-2.4.yml:  http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html#vsphere
- auth.yml : http://docs.pivotal.io/platform-automation/v2.1/configuration-management/configure-auth.html


## pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template
```
├── common-params.yml
├── dev-1
│   ├── download-product-params.yml
│   └── env-params.yml
├── opsman-install.sh
├── opsman-install.yml
├── opsman-upgrade.sh
├── opsman-upgrade.yml
├── pas.sh
├── pas.yml
├── tasks
│   ├── apply-product-changes.yml
│   ├── bbr-backup-director.sh
│   ├── bbr-backup-director.yml
│   ├── bbr-backup-pas.sh
│   ├── bbr-backup-pas.yml
│   ├── pks
│   │   └── configure-pks-cli-user
│   │       ├── task.sh
│   │       ├── task.sh.orig
│   │       ├── task.yml
│   │       └── task.yml.orig
│   ├── poweroff-vm.sh
│   ├── poweroff-vm.yml
│   ├── rename-vm.sh
│   ├── rename-vm.yml
│   ├── staged-director-config.yml
│   └── test.yml

```

### common-params.yml
```
s3:
  endpoint: http://10.10.10.199:9000
  access_key_id: ((s3_access_key_id))
  secret_access_key: ((s3_secret_access_key))
  region_name: ""
  buckets:
    platform_automation: platform-automation
    pivnet_products: pivnet-products
    installation: installation
    bbr-backup: bbr-pcfdemo

git:
  platform_pipelines:
   # uri: ssh://pivotal@10.10.10.199/platform/platform-pipelines.git
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

vcenter:
  datacenter: datacenter
  insecure: 1
  url: 10.10.10.10
  username: ((vcenter_user.username))
  password: ((vcenter_user.password))

pivnet: 
  token: ((pivnet_token))
```

### dev-1/env-params.yml
```

foundation: dev-1

#opsman_image_versioned_regexp:  .*-vsphere-(2\.4-.*).ova
opsman_image_versioned_regexp:  ops-manager-vsphere-(2\.5\.5.*).ova

#pas_product_versioned_regexp: cf-(.*).pivotal
pas_product_versioned_regexp: cf-(2\.5).pivotal
pas_stemcell_versioned_regexp: pas-stemcell/bosh-stemcell-(.*)-vsphere.*\.tgz

pks_product_versioned_regexp: pivotal-container-service-(1\.4\..*).pivotal
pks_stemcell_versioned_regexp: pks-stemcell/bosh-stemcell-(.*)-vsphere.*\.tgz

pas_config_file: cf-2.5.yml
pks_config_file: pivotal-container-service-1.4.yml
```

###  register secrets to concourse credhub.
```
## /concourse/main
credhub set -t value -n /concourse/main/s3_access_key_id -v <S3_ACCESS_KEY>
credhub set -t value -n /concourse/main/s3_secret_access_key -v "<S3_SECRET>"
credhub set -t value -n /concourse/main/pivnet_token -v <YOUR_PIVNET_TOKEN>

credhub set -t value -n /concourse/main/git_user_email -v <GIT_USER_EMAIL>
credhub set -t value -n /concourse/main/git_user_username -v <GIT_USER_NAME>

credhub set -t user -n /concourse/main/vcenter_user -z <user> -w <password>

# register ssh key for git. ex) ~/.ssh/id_rsa
credhub set -t rsa  -n /concourse/main/git_private_key  -p ~/.ssh/id_rsa 
 
cd concourse-bosh-deployment/cluster
bosh int ./concourse-creds.yml --path /atc_tls/certificate > atc_tls.cert
credhub set -t certificate -n /concourse/main/credhub_ca_cert -c ./atc_tls.cert

grep concourse_to_credhub ./concourse-creds.yml
credhub set -t user -n /concourse/main/credhub_client -z concourse_to_credhub -w <concourse_to_credhub>


## /concourse/dev-1
credhub set -t user  -n /concourse/dev-1/opsman_admin -z admin -w <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/decryption-passphrase -v <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/opsman_target -v https://opsman_url_or_IP


```

## run pipeline

```
fly -t demo sp -p opsman-install -c opsman.yml -l ./common-params.yml -l ./dev-1/env-params.yml


```
