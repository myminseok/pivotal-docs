### 백업
https://docs.pivotal.io/pivotalcf/2-3/customizing/backup-restore/backup-pcf-bbr.html

### Data product unsupported by bbr
https://docs.pivotal.io/ops-manager/2-10/install/backup-restore/disaster-recovery.html#not-supported




#### OPS manager 수동백업
https://docs.pivotal.io/pivotalcf/2-3/customizing/backup-restore/backup-pcf-bbr.html#export

#### director수동백업
https://docs.pivotal.io/pivotalcf/2-3/customizing/backup-restore/backup-pcf-bbr.html#bbr-backup-director

#### PAS 수동백업
https://docs.pivotal.io/pivotalcf/2-3/customizing/backup-restore/backup-pcf-bbr.html#bbr-backup

#### 백업 검증
원본 환경말고 새로운 환경을 준비해서 백업을 이용해서 복구해보는 절차입니다.
https://docs.pivotal.io/pivotalcf/2-3/customizing/backup-restore/backup-pcf-bbr.html#validate-backup
https://docs.pivotal.io/ops-manager/2-10/install/backup-restore/restore-pcf-bbr.html#compatibility


### concourse파이프라인을 이용한 자동백업
https://github.com/pivotal-cf/bbr-pcf-pipeline-tasks

#### 파이프라인 다운로드
```
https://github.com/pivotal-cf/bbr-pcf-pipeline-tasks
git clone https://github.com/pivotal-cf/bbr-pcf-pipeline-tasks.git
```
#### params.yml 수정 
```
skip-ssl-validation: true
pivnet-api-token: ((pivnet_token))
opsman-url: https://opsman.sampivotal.com
opsman-username: ((opsman_admin.username))
opsman-password: ((opsman_admin.password))
opsman-private-key: ((pem.private_key)) # optional, Ops Manager VM SSH private key
client-id:
client-secret:
backup-artifact-bucket: backup-artifact
storage-region: ap-northeast-2
storage-endpoint: s3.ap-northeast-2.amazonaws.com
storage-access-key-id: ((aws_access_key_id))
storage-secret-access-key: ((aws_secret_access_key))
concourse-worker-tag: external_worker
```
#### 파이프라인 배포
```
~/workspace/bbr-pcf-pipeline-tasks$ fly -t concourse sp -p bbr-backup-task -c pipeline.yml -l params.yml
```
#### 주기적 자동 백업
https://github.com/pivotalservices/concourse-pipeline-samples/tree/master/concourse-pipeline-patterns/time-triggered-pipelines/01-single-time-trigger


# restore
## backup validation by test restoring
https://docs.pivotal.io/ops-manager/2-10/install/backup-restore/restore-pcf-bbr.html#compatibility

## recreate vm and persistent disk
- bosh vms : check persisent disk damage in vcenter
- bosh -d cf-x is -i : get disk cid
- bosh delete-vm vm-cid
- delete persistent disk from vcenter manually
- bosh cck : will choose to delete disk reference
- bosh -d cf instances -i : see if the disk ref is deleted
- bosh -d cf-x recreate instance-id : will recreate a new persistent disk
- bosh -d cf-x cck : 

## detecting orphand deployment(SI) in CF.

https://docs.pivotal.io/ops-manager/2-10/install/backup-restore/incident-response-guides/lost-cf-data.html#consolidating-environment

https://docs.vmware.com/en/On-Demand-Services-SDK-for-VMware-Tanzu/0.42/on-demand-services-sdk/GUID-management.html#orphan-deployments
[
## converge
https://bosh.io/docs/deployment-convergence/
