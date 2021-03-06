# Backup director & restore

## Ref
- http://docs.pivotal.io/platform-automation/v2.1/reference/pipeline.html#installing-ops-manager-and-tiles
- https://github.com/pivotal-cf/bbr-pcf-pipeline-tasks/blob/master/tasks/bbr-backup-director/


## Config
- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-template
```
platform-automation-template
└── dev-1
    ├── config
    ├── download-product-configs
    ├── env
    │   └── env.yml
    ├── generated-config
    ├── state
    └── vars

```

### env.yml
- to get BOSH_ENVIRONMENT from ops manager for bbr cli.
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


## pipeline
- sample: https://github.com/myminseok/platform-automation-template
```
├── bbr-backup-params.yml
├── bbr-backup.yml
├── tasks
│   ├── bbr-backup-director.sh
│   └── bbr-backup-director.yml
├── bbr-backup.sh
```

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
  interpolate_folders: dev-1/env

pivnet: 
  token: ((pivnet_token))

```

###  register secret to concourse credhub.
1. get director bbr ssh key: opsman UI> director> credentials> bbr_ssh_key
1. set to concourse credhub:  

```
credhub set -t value -n /concourse/main/s3_access_key_id -v <S3_ACCESS_KEY>
credhub set -t value -n /concourse/main/s3_secret_access_key -v "<S3_SECRET>"
credhub set -t value -n /concourse/main/pivnet_token -v <YOUR_PIVNET_TOKEN>

credhub set -t value -n /concourse/main/git_user_email -v <GIT_USER_EMAIL>
credhub set -t value -n /concourse/main/git_user_username -v <GIT_USER_NAME>

# register ssh key for git. ex) ~/.ssh/id_rsa
credhub set -t rsa  -n /concourse/main/git_private_key  -p ~/.ssh/id_rsa 
 
cd concourse-bosh-deployment/cluster
bosh int ./concourse-creds.yml --path /atc_tls/certificate > atc_tls.cert
credhub set -t certificate -n /concourse/main/credhub_ca_cert -c ./atc_tls.cert

grep concourse_to_credhub ./concourse-creds.yml
credhub set -t user -n /concourse/main/credhub_client -z concourse_to_credhub -w <concourse_to_credhub>

credhub set -t user  -n /concourse/dev-1/opsman_admin -z admin -w <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/decryption-passphrase -v <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/opsman_target -v https://opsman_url_or_IP


```

## run pipeline
```
fly -t demo sp -p bbr-backup -c bbr-backup.yml -l ./bbr-backup-params.yml
```
### backup in pipeline
```
## root@4390d837-fe20-412d-6a5a-2368d07e1532:/tmp/build/7caceab2/backup-tmp/10.10.10.21_20190505T151750Z# ls -alh

# total 44G
# 17M bosh-0-bbr-credhubdb.tar
# 44G bosh-0-blobstore.tar
# 9.5M bosh-0-director.tar
# 202K metadata

```
### backup in s3
```
https:///s3.pcfdemo.net/bbr-pcfdemo/bbr-backup-director-20190430.1319.11+UTC.tgz

```

# Restore director (manual)
https://docs.pivotal.io/platform/2-8/customizing/backup-restore/backup-pcf-bbr.html


## get bbr key
opsman UI> director> credentials>  Bbr Ssh Credentials
```
$ printf --  "-----BEGIN RSA PRIVATE KEY----- MIIEkeycontents ----END RSA PRIVATE KEY-----" > bbr_key.pem
```

## deply empty director 
1. Remove bosh-state.json in opsman VM : /var/tempest/workspaces/default/deployments/bosh-state.json
2. OPSMAN UI> Apply Changes (BOSH Director only)

## restore director
```
om -e om-env.yml bosh-env > bosh-env.sh
source bosh-env.sh


bbr director \
--host HOST \
--username bbr \
--private-key-path BBR-PRIVATE-KEY-FILE \
restore \
--artifact-path PATH-TO-DIRECTOR-BACKUP

bbr director \
--host HOST \
--username bbr \
--private-key-path BBR-PRIVATE-KEY-FILE \
restore-cleanup
```

## check deployments
```
bosh update-resurrection off
bosh deployments
BOSH cck ( all deployments)

```



