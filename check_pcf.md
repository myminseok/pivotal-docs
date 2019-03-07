
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


## PAS 중지/시작 방법
본 내용은 다음 문서를 요약합니다 
- https://docs.pivotal.io/pivotalcf/2-4/adminguide/start-stop-vms.html

### 중지 순서

#### 0. PCF VM 정합성 점검
- opsmanager vm에 ssh 접속
- bosh deployment 목록 추출.
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name
cf-c8399c1d00f7742d47a1

```

- PAS VM의 상태를 확인합니다. 
bosh vms의 결과에서 vm의 상태가 "failing", "running"의 값이 번갈아 나오는 경우, VM이 재시작할 때 VM의 permission이 변경된 경우입니다. 
BOSH resurrection이 개입하기 전에 vSphere HA가 VM을 재시작한 경우 또는 VM의 resurrection state가 "off"인 경우 제대로 동작하지 않습니다. 

```
ubuntu@opsmanager-2-4:~$ bosh -d cf-c8399c1d00f7742d47a1 vms
Using environment '10.10.10.21' as client 'ops_manager'

Task 277537. Done

Deployment 'cf-c8399c1d00f7742d47a1'

Instance                                                            Process State  AZ   IPs           VM CID                                   VM Type      Active
clock_global/bc941f92-6586-415f-9d84-801753590706                   running        az1  10.10.12.32   vm-06bfe656-8ef3-47a9-8ae8-1f9aedfc9f0b  medium.disk  true
cloud_controller/2e560100-6cad-4f52-b231-c7a0a4e40879               running        az1  10.10.12.28   vm-5ed0bcf0-e61c-4c04-a5ff-7297f0be2f3a  medium.disk  true
cloud_controller_worker/50185c81-111c-4501-bb5b-341f365528b6        running        az1  10.10.12.33   vm-fe6066ad-4537-4f98-a7b5-9e1cdb2cb202  micro        true
consul_server/5be6e4da-9565-47f8-a422-ad8b913dfcd0                  running        az1  10.10.12.21   vm-ac7b948e-0329-4a8d-bea2-e0ec0d820554  micro        true
diego_brain/0a8e998f-73d8-4def-9dd7-59e807f42a30                    running        az1  10.10.12.34   vm-caeae1f9-5faf-4769-942d-10085259b635  small        true
diego_cell/49c828db-8e3e-4900-88bd-3cb0df62aac3                     running        az1  10.10.12.35   vm-7ffe340d-775b-43e1-a2b9-25d0e725779b  xlarge.disk  true
diego_cell/4c976cec-a48b-4c91-be38-77f697e415ce                     running        az2  10.10.12.37   vm-cc50ba9a-b076-4529-9809-d27972277963  xlarge.disk  true
diego_cell/d40c49a5-f0db-4923-9414-bc33d754aec5                     running        az1  10.10.12.50   vm-f265858a-a8d1-4ce9-a803-987daacc06f7  xlarge.disk  true
diego_cell/ea62191b-e35c-4b51-903c-ee9a8cb79c23                     running        az1  10.10.12.36   vm-01ea950b-320f-4424-a749-c3c7725316e8  xlarge.disk  true
diego_cell/ed084dc3-12d2-4036-b690-875233e11b07                     running        az2  10.10.12.51   vm-3f1c185f-7d7e-4efc-8612-3dff8898572e  xlarge.disk  true
diego_database/68e53f50-60b9-4da8-9848-a8a23582d5ad                 running        az1  10.10.12.26   vm-5c29d4ea-c119-4234-ae28-5890e904616c  micro        true
doppler/a656f4e8-67ce-4dff-8bbe-4b6c8ff2bab7                        running        az1  10.10.12.41   vm-d8b79926-f86d-4ff5-8eda-bb7dbff48167  medium.mem   true
ha_proxy/10348fe2-c233-4403-871f-801f707eefac                       running        az1  10.10.12.100  vm-4d3acb40-78a4-4ab4-a1be-44b26d5822a3  micro        true
loggregator_trafficcontroller/97e6f1e6-1c14-4063-8071-84b6a6ed9d06  running        az1  10.10.12.38   vm-8438e639-3027-459a-82e0-5bfde6a582c1  micro        true
mysql/6c1bbe7d-bb6c-4bbd-a2fb-0f6829ffa097                          running        az1  10.10.12.25   vm-b670f4b5-87f2-4079-9531-53ddcc3415fd  large.disk   true
mysql_monitor/a9592e33-2e1d-4def-8e57-8aba872539be                  running        az1  10.10.12.31   vm-a9020d56-ae89-4bd3-aea1-05117f1f9dd8  micro        true
mysql_proxy/9087ea37-b938-4b84-bec6-524f0b6c81c6                    running        az1  10.10.12.24   vm-1ea5de0c-b6b2-4937-9e01-23fc567c192d  micro        true
nats/ca73a2ae-02f3-4aad-a835-d1ce4d865f77                           running        az1  10.10.12.22   vm-5d16fdd6-3d87-4b73-a9f5-056b0a6cf187  micro        true
nfs_server/b3bbeca0-a444-4065-a0cb-a72adca6029d                     running        az1  10.10.12.23   vm-4faf9598-ad94-432d-a9e9-e8a5fa1ee6e1  medium       true
router/92db4a73-0c72-498d-9367-02aba9b0fd0e                         running        az1  10.10.12.29   vm-0ec49e2f-f2a4-4d3c-affb-4622f8915bf7  micro        true
syslog_adapter/83403679-0f06-47a2-b7b0-5581e99808e8                 running        az1  10.10.12.39   vm-2eb42a84-2e51-4d54-9aab-0951aab183bc  micro        true
syslog_scheduler/84d3aeb5-11cd-4afb-9d3d-fc71a520a628               running        az1  10.10.12.40   vm-f88a4dae-3c87-4571-acb7-a0f1ea800c7b  micro        true
uaa/41dbcc01-4115-4fe1-bdff-51fcf24aa8dd                            running        az1  10.10.12.27   vm-ee883bea-adf6-4ffd-8cae-55c2cbc98eed  medium.disk  true

23 vms

Succeeded
```

bosh cloud-check에 deployment이름을 지정하여 VM상태 점검합니다. 
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

#### 1. 분산 시스템 VM을 1개로 scale down
1. Ops Manager UI > Pivotal Application Service tile> resource config tab 
2. 분산 시스템 VM을 1개로 scale down
- concul_server
- mysql
3. Ops Manager UI main page에서 'apply changes' 클릭.

#### 2. 모든 PAS VM 중지.

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

### 시작 순서
- bosh deployment 목록 추출.
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name
cf-c8399c1d00f7742d47a1

```
- 모든 vm 시작
bosh -d MY-DEPLOYMENT start

```
bosh -d cf-c8399c1d00f7742d47a1 start

```

- PAS VM의 상태를 확인합니다. 
bosh vms의 결과에서 vm의 상태가 "failing", "running"의 값이 번갈아 나오는 경우, VM이 재시작할 때 VM의 permission이 변경된 경우입니다. 
BOSH resurrection이 개입하기 전에 vSphere HA가 VM을 재시작한 경우 또는 VM의 resurrection state가 "off"인 경우 제대로 동작하지 않습니다. 

```
ubuntu@opsmanager-2-4:~$ bosh -d cf-c8399c1d00f7742d47a1 vms
```

- apps manager UI에 접속해봅니다.
화면이 뜨고 로그인이 성공하면 정상적으로 PAS가 기동한 것입니다.
```
https://apps.system.<PAS-DOMAIN>

ID: admin
password: Ops Manager UI > Pivotal Application Service tile> credentials tab > UAA / admnin  Credentials 클릭하여 내용을 복사
```

