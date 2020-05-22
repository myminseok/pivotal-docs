# Backup TAS & restore

## prerequisits
- [prepare concourse cluster with credhub](/concourse-with-credhub.md)
- [get pipeline template](/platform-automation/get-pipeline-template.md)
- [set credhub variables](/platform-automation/set-credhub-variables.md)

## configure set-pipeline variables
- official guide: https://docs.pivotal.io/platform-automation/v4.3/inputs-outputs.html

#### platform-automation-template/awstest/opsman/env.yml
- to get BOSH_ENVIRONMENT from ops manager for bbr cli.
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


#### platform-automation-template/awstest/pipeline-vars/params.yml
- [sample code](https://github.com/myminseok/platform-automation-template/blob/master/dev/pipeline-vars/params.yml)
```

foundation: dev-1

s3:
  endpoint: https:///s3.pcfdemo.net
  access_key_id: ((s3_access_key_id))
  secret_access_key: ((s3_secret_access_key))
  region_name: "dummy"
  buckets:
    platform_automation: platform-automation
    foundation: dev-1
    pivnet_products: pivnet-products
    installation: installation
    bbr-backup: bbr-pcfdemo   <<=================== set this.
...

```


## pipeline
- [sample code](https://github.com/myminseok/platform-automation-template)
```
├── bbr-backup-params.yml
├── bbr-backup.yml
├── tasks
│   ├── bbr-backup-pas.sh
│   └── bbr-backup-pas.yml
├── bbr-backup.sh
```
###  register secret to concourse credhub.
1. get director bbr ssh key: opsman UI> director> credentials> bbr_ssh_key
2. [set to credhub](/platform-automation/set-credhub-variables.md)


## deploy concourse pipeline
```
fly -t demo sp -p bbr-backup -c bbr-backup.yml -l ./bbr-backup-params.yml
```
- each foundation will set pipeline using per foundation configs from platform-automation-configuration. for example, pipeline for awstest can be set as following:
- [sample code](https://github.com/myminseok/platform-automation-template/bbr-backup.sh)

``` bash
$ fly -t <FLY-TARGET> login -c https://your.concourse/ -b -k
$ bbr-backup.sh <FLY-TARGET> <FOUNDATION>

$ bbr-backup.sh demo dev
```



### backup in pipeline
```
## root@4390d837-fe20-412d-6a5a-2368d07e1532:/tmp/build/7caceab2/cf-c8399c1d00f7742d47a1_20190505T123820Z# ls -alh
#total 17G
#10K backup_restore-0-azure-blobstore-backup-restorer.tar
#20K backup_restore-0-backup-restore-notifications.tar
#20K backup_restore-0-backup-restore-pcf-autoscaling.tar
#1.2M backup_restore-0-bbr-cfnetworkingdb.tar
#176M backup_restore-0-bbr-cloudcontrollerdb.tar
#10K backup_restore-0-bbr-credhubdb.tar
#10K backup_restore-0-bbr-routingdb.tar
#120K backup_restore-0-bbr-uaadb.tar
#423M backup_restore-0-bbr-usage-servicedb.tar
#10K backup_restore-0-nfsbroker-bbr.tar
#10K backup_restore-0-s3-unversioned-blobstore-backup-restorer.tar
#10K backup_restore-0-s3-versioned-blobstore-backup-restorer.tar
#33K metadata
#10K nfs_server-0-blobstore-backup.tar
#16G nfs_server-0-blobstore.tar


```
### backup in s3
```
https:///s3.pcfdemo.net/bbr-pcfdemo/bbr-backup-pas-20190430.1319.11+UTC.tgz

```

# Restore PAS (manual)
https://docs.pivotal.io/pivotalcf/2-5/customizing/backup-restore/restore-pcf-bbr.html#bosh-only-deploy
https://content.pivotal.io/blog/tutorial-automating-ert-backups-with-bbr-and-concourse

## get bosh env.
opsman-env.yml
```
target: https://myopsman.domain
connect-timeout: 30                 # default 5
request-timeout: 3600               # default 1800
skip-ssl-validation: true           # default false
username: admin
password: PASSWORD
decryption-passphrase: PASSWORD

```
om --env ./opsman-env.yml  bosh-env > bosh-env.sh
source ./bosh-env.sh


## run cck for PAS and other tiles
```
bosh -e $BOSH_ENVIRONMENT \
--ca-cert $BOSH_CA_CERT \
-d DEPLOYMENT-NAME -n cck \
--resolution delete_disk_reference \
--resolution delete_vm_reference
```

## upload stemcell for PAS

## redeploy PAS
run apply change on OPSMAN UI


## restore PAS
1.
```
bbr deployment \
--target $BOSH_ENVIRONMENT \
--username $BOSH_CLIENT \
--password $BOSH_CLIENT_SECRET \
--deployment DEPLOYMENT-NAME \
--ca-cert $BOSH_CA_CERT \
restore \
--artifact-path PATH-TO-PAS-BACKUP
```
example
```
./bbr deployment --target 10.0.0.5 
--username ops_manager 
--password <> 
--deployment cf-9d536bda70e40707c83d 
--ca-cert /var/tempest/workspaces/default/root_ca_certificate restore 
--artifact-path cf-9d536bda70e40707c83d_20170810T152801Z

```
1. run apply change on OPSMAN UI


