# Upgrade Automation for PAS (vsphere only)
- Minor upgrade means any change of first or second digit in version scheme. In PCF, it may includes some breaking changes. 2.5.* -> 2.6.*
- Patch upgrade: any change of the third digit in version scheme. It is safe to upgrade without any architectural or configuration changes in product. 2.5.1 -> 2.5.2


refer to
- https://docs.pivotal.io/pivotalcf/2-5/customizing/upgrading-pcf.html
- https://docs.pivotal.io/pivotalcf/2-5/upgrading/checklist.html


## Check platform integrity
- opsman UI 
- bosh cck command

## Backup
- opsman export 
- PAS, director backup via bbr. see concourse pipeline https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/bbr-backup-pas.md
<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/bbr-backup.png" width="500">

## Check release note
- see any known issues

## Check compativility matrix and tile upgrade if need.
- refer to https://docs.pivotal.io/resources/product-compatibility-matrix.pdf
- backup(if there is any change)
- PAS, director backup via bbr. see concourse pipeline https://github.com/myminseok/pivotal-docs/blob/

## Check platform capacity for upgrade
- check cluster healthiness
- bosh clean-up --all


## **patch** opsman procedure
1. export opsman configuration
2. shutdown old opsman and delete VM.
3. install new opsman VM
4. import installation
5. configure director tile from the exported opsman configuration in step 1.
6. apply director change


<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/patch-opsman.png" width="500">
refer to the concourse pipeline for the following procedure: https://github.com/myminseok/platform-automation-template/blob/master/opsman-upgrade.yml

## **Minor** upgrade opsman procedure
There are manual steps here which is dependent on product feature change.
1. (concourse) export opsman configuration (platform-automation-tasks/tasks/export-installation.yml)
2. (concourse) shutdown old opsman VM and rename VM.
3. (concourse) install new opsman VM
4. (concourse) import installation to the new opsman VM.
5. (**Manual**) configure any property changes for director tile via opsman UI.
6. (concourse) extract staged director tile config with placeholder
7. (**Manual**) edits any property change in configuration including the staged director config file and save into git repo. it will be used for "configure director" job later.
8. (concourse) extract staged director tile config with credentials.
9. (**Manual**) configure the credentials from step 8 to concourse credhub if there are any changes
10. (concourse) configure director tile from opsman configuration
11. (concourse) apply director change


<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/major-upgrade-opsman.png" width="500">
In the pipeline, all dependency removed between jobs because sometimes it is required to run a specific job manually for efficiency. such as if there is a fix in configuration on git. Skip “upload stemcells” to reuse pre-uploaded stemcells or there are optional steps sometimes. refer to the concourse pipeline for the following procedure: https://github.com/myminseok/platform-automation-template/blob/master/opsman-upgrade.yml

## **Patch** PAS procedure
1. (concourse) (optional) upload stemcells
2. (concourse) upload release - stage release
3. (concourse) apply PAS tile change

<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/patch-opsman.png" width="500">
refer to the concourse pipeline for the following procedure: https://github.com/myminseok/platform-automation-template/blob/master/pas.yml

## **Minor** upgrade PAS procedure
There are manual steps here which is dependent on product feature change.
1. (concourse) PAS backup via bbr. see concourse pipeline https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/bbr-backup-pas.md
2. (concourse) (optional)extract staged PAS tile config with credentials for backup.
3. (concourse) (optional)upload stemcells 
4. (concourse) upload release - stage release
5. (**Manual**) configure any property change for PAS tile via opsman UI.
6. (concourse) extract staged PAS tile config with placeholder
7. (**Manual**) edits any property change in configuration including the staged PAS config file and save into git. it will be used for "configure PAS" job later.
8. (concourse) extract staged PAS tile config with credentials.
9. (**Manual**) configure the credentials from step 8 to concourse credhub if there are any changes
10. (concourse) apply PAS tile change

<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/major-upgrade-pas.png" width="500">
In the pipeline, all dependency removed between jobs because sometimes it is required to run a specific job manually for efficiency. such as if there is a fix in configuration on git. Skip “upload stemcells” to reuse pre-uploaded stemcells or there are optional steps sometimes. refer to the concourse pipeline for the following procedure:  https://github.com/myminseok/platform-automation-template/blob/master/pas.yml

