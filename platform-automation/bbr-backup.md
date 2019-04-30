## Ref
- http://docs.pivotal.io/platform-automation/v2.1/reference/pipeline.html#installing-ops-manager-and-tiles


## Config
- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-configuration-template
```
platform-automation-configuration-template
└── dev-1
    ├── config
    ├── download-product-configs
    ├── env
            director-bbr-private-key.yml
    │   └── env.yml
    ├── generated-config
    ├── state
    └── vars

```

### env.yml
- http://docs.pivotal.io/platform-automation/v2.1/configuration-management/configure-env.html
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

### director-bbr-private-key.yml:  
```
((director-bbr-private-key))
```


## pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template

### bbr-backup.yml

### bbr-backup-params.yml
```

foundation: dev-1

s3:
  endpoint: https:///s3.pcfdemo.net
  access_key_id: ((s3_access_key_id))
  secret_access_key: ((s3_secret_access_key))
  region_name: ""
  buckets:
    platform_automation: platform-automation
    foundation: dev-1
    pivnet_products: pivnet-products
    installation: installation
    bbr-backup: bbr-pcfdemo

git:
  platform-automation-pipeline:
    uri: pivotal@git.pcfdemo.net/platform/platform-pipelines.git
  platform_automation_tasks:
    uri: pivotal@git.pcfdemo.net/platform/platform_automation_tasks.git
  configuration:
    uri: pivotal@git.pcfdemo.net:platform/platform-conf.git
  variable:
    uri: pivotal@git.pcfdemo.net:platform/platform-conf.git
  user: 
    email: ((git_user.email))
    username: ((git_user.username))
  private_key: ((git_private_key.private_key))

credhub:
  server: https://concourse.pcfdemo.net:8844
  ca_cert: ((credhub_ca_cert.certificate))
  client: ((credhub_client.username))
  secret: ((credhub_client.password))
  interpolate_folders: dev-1/config dev-1/env


pivnet: 
  token: ((pivnet_token))

```

###  register secret to concourse credhub.
1. get director bbr ssh key: opsman UI> director> credentials> bbr_ssh_key
1. set to concourse credhub:  
```
credhub set -t rsa -n /concourse/dev-1/director-bbr-private-key -p ./bosh-bbr.key
```

## run pipeline
```
fly -t demo sp -p bbr-backup -c bbr-backup.yml -l ./bbr-backup-params.yml
```

### backup in s3
```
https:///s3.pcfdemo.net/bbr-pcfdemo/bbr-backup-director-20190430.1319.11+UTC.tgz
```
