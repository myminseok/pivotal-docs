
# Pivotal Application Service 중지/시작 방법
본 내용은 다음 문서를 요약합니다 
- https://docs.pivotal.io/pivotalcf/2-4/adminguide/start-stop-vms.html

## 기본 작업 
다음 PCF 시스템을 다루기 위한 기본적인 작업에 대한 가이드입니다.

### Ops Manager VM에 ssh 접속하기
ops manager에 ssh 접속하기 위한 private key를 확보 후 ssh 접속합니다.

```
chmod 600 ops_mgr.pem
ssh -i ops_mgr.pem ubuntu@my-opsmanager-fqdn.example.com
```

### BOSH director에 login
PAS 를 관리하는 bosh director에 로그인하는 방법입니다.
1.	Ops Manager UI > director tile> credentials tab > Bosh Commandline Credentials> Link to credential 클릭하여 아래 형식의 내용을 복사
2.	Ops Manager VM에 ssh접속
3.	vi ~/.profile에 아래 형태로 편집하여 저장
```
alias bosh=" BOSH_CLIENT=ops_manager BOSH_CLIENT_SECRET=xxxx BOSH_CA_CERT=/var/tempest/workspaces/default/root_ca_certificate BOSH_ENVIRONMENT=10.10.10.21 bosh"
```
4.	환경정보 활성화
```
source  ~/.profile
```
5.	Bosh 환경정보 조회
결과가 아래와 같이 나오면 정상입니다.
```
ubuntu@opsmanager-2-4:~$ bosh env
Using environment '10.10.10.21' as client 'ops_manager'

Name      p-bosh
UUID      2117b308-7f9b-4dd4-9fde-5916e7f3049c
Version   268.2.2 (00000000)
CPI       vsphere_cpi
Features  compiled_package_cache: disabled
          config_server: enabled
          local_dns: enabled
          power_dns: disabled
          snapshots: disabled
User      ops_manager

Succeeded
```



## PAS 중지 순서
#### 0. 장애 예방을 위해 정지 전에 [bbr](https://docs.pivotal.io/pivotalcf/2-4/customizing/backup-restore/backup-pcf-bbr.html)을 통해 백업을 해야합니다.
#### 1. opsmanager vm에 ssh 접속
#### 2. bosh director login
#### 3. PAS VM 정합성 점검
1. opsmanager vm에 ssh 접속
2. bosh deployment 목록 추출.
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name
cf-c8399c1d00f7742d47a1

```
3. PAS VM의 상태를 확인합니다. 
bosh vms의 결과에서 vm의 상태가 "running"이어야합니다.

```
ubuntu@opsmanager-2-4:~$ bosh -d cf-c8399c1d00f7742d47a1 vms
Using environment '10.10.10.21' as client 'ops_manager'

Task 277537. Done

Deployment 'cf-c8399c1d00f7742d47a1'

Instance                                                            Process State  AZ   IPs           VM CID                                   VM Type      Active
clock_global/bc941f92-6586-415f-9d84-801753590706                   running        az1  10.10.12.32   vm-06bfe656-8ef3-47a9-8ae8-1f9aedfc9f0b  medium.disk  true
cloud_controller/2e560100-6cad-4f52-b231-c7a0a4e40879               running        az1  10.10.12.28   vm-5ed0bcf0-e61c-4c04-a5ff-7297f0be2f3a  medium.disk  true

중략...

uaa/41dbcc01-4115-4fe1-bdff-51fcf24aa8dd                            running        az1  10.10.12.27   vm-ee883bea-adf6-4ffd-8cae-55c2cbc98eed  medium.disk  true

23 vms

Succeeded
```

4. bosh cloud-check에 deployment이름을 지정하여 VM상태 점검합니다. 
bosh cloud-check 실행중에 VM이상이 발견되면 가이드에 따라 복구합니다. 가이드: https://bosh.io/docs/cck/ 를 참조합니다.
```
ubuntu@opsmanager-2-4:~$ bosh -d  cf-c8399c1d00f7742d47a1 cloud-check 
Performing cloud check...

Processing deployment manifest
------------------------------

Director task 622
  Started scanning 1 vms
  Started scanning 1 vms > Checking VM states. Done (00:00:00)
  Started scanning 1 vms > 1 OK, 0 unresponsive, 0 missing, 0 unbound, 0 out of sync. Done (00:00:00)
     Done scanning 1 vms (00:00:00)

  Started scanning 0 persistent disks
  Started scanning 0 persistent disks > Looking for inactive disks. Done (00:00:00)
  Started scanning 0 persistent disks > 0 OK, 0 missing, 0 inactive, 0 mount-info mismatch. Done (00:00:00)
     Done scanning 0 persistent disks (00:00:00)

Task 622 done

Started     2015-01-09 23:29:34 UTC
Finished    2015-01-09 23:29:34 UTC
Duration    00:00:00

Scan is complete, checking if any problems found...
No problems found

```

#### 4. 분산 시스템 VM을 1개로 scale down
1. Ops Manager UI > Pivotal Application Service tile> resource config tab 
2. 분산 시스템 VM을 1개로 scale down
- concul_server
- mysql
3. Ops Manager UI main page에서 'apply changes' 클릭.

#### 5. 모든 PAS VM 중지.
- bosh deployment 목록 추출.
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name
cf-c8399c1d00f7742d47a1

```

- 모든 vm 중지 및 삭제
bosh -d MY-DEPLOYMENT stop --hard
'--hard' 옵션은 VM을 삭제하지만 영구 디스크는 보존됩니다.
```
bosh -d cf-c8399c1d00f7742d47a1 stop --hard

```

#### 5. bosh director VM 중지
- vcenter를 통해 중지.

#### 6. ops manager VM 중지
- vcenter를 통해 중지.


## PAS 기동 순서
#### 1. ops manager VM 시작
- vcenter를 통해 시작.

#### 2. bosh director VM 시작
- vcenter를 통해 시작.

#### 3. PAS VM 기동 
1. bosh deployment 목록 추출.
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name
cf-c8399c1d00f7742d47a1

```
2. 모든 vm 기동
bosh -d MY-DEPLOYMENT start

```
bosh -d cf-c8399c1d00f7742d47a1 start

```

3. PAS VM의 상태를 확인합니다. 
bosh vms의 결과에서 vm의 상태가 "failing", "running"의 값이 번갈아 나오는 경우, VM이 재시작할 때 VM의 permission이 변경된 경우입니다. 
BOSH resurrection이 개입하기 전에 vSphere HA가 VM을 재시작한 경우 또는 VM의 resurrection state가 "off"인 경우 제대로 동작하지 않습니다. 

```
ubuntu@opsmanager-2-4:~$ bosh -d cf-c8399c1d00f7742d47a1 vms
```

#### 4. PAS 점검

1. (테스트) bosh cloud-check에 deployment이름을 지정하여 VM상태 점검합니다. 
bosh cloud-check 실행중에 VM이상이 발견되면 가이드에 따라 복구합니다. 가이드: https://bosh.io/docs/cck/ 를 참조합니다.
```
ubuntu@opsmanager-2-4:~$ bosh -d  cf-c8399c1d00f7742d47a1 cloud-check 
Performing cloud check...
```


2. bosh resurrector  상태 점검
- VM의 resurrection상태를 확인합니다. "Resurrection Paused" 컬럼이 false이면 활성화된 것입니다.
```
ubuntu@opsmanager-2-4:~$ bosh -d <DEPLOYMENT-ID> instances -i

Deployment 'service-instance_8c134e2f-1694-4879-a7fd-29b993b9a7e0'

Instance                                    Process State       AZ   IPs          State    VM CID                                   VM Type  Disk CIDs                                  Agent ID                              Index  Resurrection  Bootstrap  Ignore
                                                                                                                                                                                                                                     Paused
mysql/48a89f85-32f6-4ba0-90b0-d622b4d4c91c  unresponsive agent  az2  10.10.14.32  started  vm-84d1b5c9-a1ea-43e2-b64d-a10fb6fa7509  small    disk-82d9dace-e92c-439d-8e72-b14c25f5f3e6  ad58b043-617e-459d-b35a-d6f825c33941  0      false         true       false

```
만약 활성화되어있지 않다면 bosh resurrection state를 "on"으로 해줍니다.
```
bosh update-resurrection  on -d cf-c8399c1d00f7742d47a1
Using environment '10.10.10.21' as client 'ops_manager'
Succeeded

```

bosh tasks이력에 'scan and fix' task가 있는지 확인합니다. (https://bosh.io/docs/resurrector/#audit)
- VM 수준에서 문제가 생기면 bosh resurrection이 작동하는 것을 확인할 수 있습니다. 
- User: health_monitor, Deployment: scan and fix...
```
ubuntu@opsmanager-2-4:~$ bosh tasks

ID      State       Started At                    Last Activity At              User            Deployment                                             Description   Result
277594  processing  Thu Mar  7 06:40:42 UTC 2019  Thu Mar  7 06:40:42 UTC 2019  health_monitor  service-instance_8c134e2f-1694-4879-a7fd-29b993b9a7e0  scan and fix  -

1 tasks

```
또는 task이력을 확인할 수 있습니다.
```
bosh tasks -ar | grep 'scan and fix'

```


#### 5. 분산 시스템 VM을 scale up
문제가 없다면 분산 시스템 VM을 scale up합니다.
1. Ops Manager UI > Pivotal Application Service tile> resource config tab 
2. 분산 시스템 VM을 원하는 갯수로 scale up
- concul_server
- mysql
3. Ops Manager UI main page에서 'apply changes' 클릭.



#### 6. app 테스트
-  (테스트) apps manager UI에 접속해봅니다.
화면이 뜨고 로그인이 성공하면 정상적으로 PAS가 기동한 것입니다.
```
https://apps.system.<PAS-DOMAIN>

ID: admin
password: Ops Manager UI > Pivotal Application Service tile> credentials tab > UAA / admnin  Credentials 클릭하여 내용을 복사
```

- (테스트) 샘플애플리케이션 배포
```
cf login -a api.system.<PCF-DOMAIN> --skip-ssl-validation

git clone https://github.com/myminseok/spring-music

cd spring-music

cf push -f manifest.yml

cf apps

name                 requested state   instances   memory   disk   urls
spring-music         started           1/1         1G       1G     spring-music-chatty-ardvark.apps.xxxx.net
```


