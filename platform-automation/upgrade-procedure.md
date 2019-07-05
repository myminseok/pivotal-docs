# Upgrade for PAS
- Major upgrade means any change of first or second digit in version scheme. 2.5.* -> 2.6.*
- Patch/Minor upgrade: any change of the thrid digit in version scheme.2.5.1 -> 2.5.2
refer to https://docs.pivotal.io/pivotalcf/2-5/upgrading/checklist.html


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
- checl cluster healthyness
- bosh clean-up

## **Minor/patch** opsman. 
1. export opsman configuration 
##### folloging task is done by single job using platform-automation-tasks/tasks/upgrade-opsman.yml
2. shutdown old opsman and delete VM.
3. install new opsman VM
4. import installation
5. configure director tile from the exported opsman configuration in step 1.
6. apply director change

<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/patch-opsman.png" width="500">
refer to the concourse pipeline for the following procedure: https://github.com/myminseok/platform-automation-pipelines-template/blob/master/opsman-upgrade.yml

## **Major** upgrade opsman. 
1. export opsman configuration (platform-automation-tasks/tasks/export-installation.yml)
2. shutdown old opsman VM and rename VM.
3. install new opsman VM
4. import installation to the new opsman VM.
5. **(Manual)** configure any property change for director tile via opsman UI.
6. extract staged director tile config with placeholder
7. **(Manual)** edits any property change in configuration and save into git. it will be used for "configure director" job later.
8. extract staged director tile config with credentials. 
9. **(Manual)** configure the credentials from step 8 to concourse credhub.
10. configure director tile from opsman configuration
11. apply director change

<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/major-upgrade-opsman.png" width="500">
In the pipeline, all dependency removed between jobs because it is required to run a specific job manually sometimes. such as if there is a fix in configuraton on git. or there are optional steps sometimes. 
refer to the concourse pipeline for the following procedure: https://github.com/myminseok/platform-automation-pipelines-template/blob/master/opsman-upgrade.yml

## **Minor/patch** PAS
1. (optional)upload stemcells
2. upload release - stage release 
3. apply PAS tile change

<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/patch-opsman.png" width="500">
refer to the concourse pipeline for the following procedure: https://github.com/myminseok/platform-automation-pipelines-template/blob/master/pas.yml

## **Major** upgrade PAS
1. PAS backup via bbr. see concourse pipeline https://github.com/myminseok/pivotal-docs/blob/
2. (optional)extract staged PAS tile config with credentials for backup.
3. (optional)upload stemcells
4. upload release - stage release
5. **(Manual)**) configure any property change for PAS tile via opsman UI.
6. extract staged PAS tile config with placeholder
7. **(Manual)** edits any property change in configuration and save into git. it will be used for "configure PAS" job later.
8. extract staged PAS tile config with credentials. 
9. **(Manual)** configure the credentials from step 8 to concourse credhub.
10. apply PAS tile change


<img src="https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/major-upgrade-pas.png" width="500">
In the pipeline, all dependency removed between jobs because it is required to run a specific job manually sometimes. such as if there is a fix in configuraton on git. or there are optional steps sometimes. 
refer to the concourse pipeline for the following procedure: https://github.com/myminseok/platform-automation-pipelines-template/blob/master/pas.yml

