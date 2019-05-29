
# opsman recovery(manual)
※ 참고사이트 : https://docs.pivotal.io/pivotalcf/2-4/customizing/backup-restore/restore-pcf-bbr.html

1. opsmanager installation.zip백업 (pipeline을 통해 minio 백업파일 저장)
1. opsmanager vm 수동power off
1. pipeline 통해 inatall opsmanager 기동
1. opsmanager 사이트를 사용하여 백업한 installation.zip파일 올리기
    !! decription passphrase 값이 틀리면 opsmanager 삭제 후 재 생성해야함
1. opsmanager 와 director연결 확인
    bosh vms 확인
    bosh instances 확인

# director recovery(manual)
※ https://docs.pivotal.io/pivotalcf/2-4/customizing/backup-restore/restore-pcf-bbr.html#deploy-import (Step 6부터)

1. bbr_keyp_pem 파일 생성 (opsmanager > director > credential > Bbr Ssh Credentials )
    printf --  "-----BEGIN RSA PRIVATE KEY----- MIIEkeycontents ----END RSA PRIVATE KEY-----" > bbr_key.pem
1. screen설지 apt-get install screen 
1. bbr 복구
screen -S bbr (session 유지를 위해 사용 )
```
bbr director \
--private-key-path PRIVATE-KEY-FILE \
--username bbr \
--host HOST \
restore \
--artifact-path PATH-TO-DIRECTOR-BACKUP
```

# PAS recovery(manual)
 https://docs.pivotal.io/pivotalcf/2-4/customizing/backup-restore/restore-pcf-bbr.html#bosh-cck 

1. (optional) bosh director vm snapshot(vsphere)
2. Step 11
PAS 전체 Delete (deployments 이름으로 PAS 검색해서 Delete)
To delete disk references, run the following command
```
bosh -e DIRECTOR_IP \
--ca-cert /var/tempest/workspaces/default/root_ca_certificate \
-d cf-DEPLOYMENT -n cck \
--resolution delete_disk_reference \
--resolution delete_vm_reference
```
3. Step 12:  Redeploy PAS
```
PAS MySQL 1개로 조정 
opsmanager PAS apply-change
!!!  실패시 director 를 snapshot으로 원복후, 2번부터 다시 시작.
!!!  apply change에서 vm get_state에러 발생시:
ubuntu@opsmanager-2-4:/var/tempest/workspaces/default/deployments$ sudo chmod 777 ./cf-DEPLOYMENT.yml
ubuntu@opsmanager-2-4:/var/tempest/workspaces/default/deployments$ bosh --deployment=cf-DEPLOYMENT deploy /var/tempest/workspaces/default/deployments/cf-DEPLOYMENT.yml --recreate --fix
bosh vms
```
4. Step 13: (Optional) Restore Service Data
Warning: BBR does not back up or restore any service data.
For example, if you are using Redis for PCF v1.14, see Using BOSH Backup and Restore (BBR).
5. Step 14: Restore PAS
```
bbr deployment \
--target 1DIRECTOR_IP \
--username ops_manager\
--password xxxxxx \
--deployment cf-DEPLOYMENT \
--ca-cert /var/tempest/workspaces/default/root_ca_certificate \
restore \
--artifact-path /home/ubuntu/cf-DEPLOYMENT_TIMESTAMP_FOLDER
```
- 전체 tile에 대해 Apply change 수행 


!! 실패시 restore-cleanup
