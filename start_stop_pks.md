
# Pivotal Container Service 중지/시작 방법
본 내용은 다음 문서를 요약합니다 
- https://docs.pivotal.io/pivotalcf/2-4/adminguide/start-stop-vms.html

## 기본작업
opsmanager, bosh director login등은 아래 문서를 참고하십시오.
- https://github.com/myminseok/pivotal-docs/blob/master/start_stop_pcf.md

## PKS 중지 순서

1. opsmanager vm에 ssh 접속
2. bosh deployment 목록 추출.
3. deployment별로 상태점검
4. deployment별로 중지를 합니다. 순서는 상관없습니다.
- Kubernetes cluster
- PKS
- harbor
-  ...

#### 0. PKS VM 정합성 점검
1. deployment 조회
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name
pivotal-container-service-182dfebc12215814ec6d
service-instance_2f16abef-a827-4e35-af6d-6b169b607eda
service-instance_8c134e2f-1694-4879-a7fd-29b993b9a7e0

```
2. Kubernetes cluster, PKS, harbor 클러스터의 VM 상태를 확인합니다. 
bosh vms의 결과에서 vm의 상태가 "failing", "running"의 값이 번갈아 나오는 경우, VM이 재시작할 때 VM의 permission이 변경된 경우입니다. 
BOSH resurrection이 개입하기 전에 vSphere HA가 VM을 재시작한 경우 또는 VM의 resurrection state가 "off"인 경우 제대로 동작하지 않습니다. 

```
ubuntu@opsmanager-2-4:~$ bosh -d pivotal-container-service-182dfebc12215814ec6d vms
Using environment '10.10.10.21' as client 'ops_manager'

Task 277618. Done

Deployment 'pivotal-container-service-182dfebc12215814ec6d'

Instance                                                        Process State  AZ   IPs          VM CID                                   VM Type  Active
pivotal-container-service/40d78256-5912-4778-95e1-e963e3c6da66  running        az2  10.10.10.22  vm-0f794d91-9411-474e-b912-2bc5700f783c  micro    true

1 vms

Succeeded
```

3. bosh cloud-check에 Kubernetes cluster, PKS, harbor deployment이름을 지정하여 VM상태 점검합니다. 
bosh cloud-check 실행중에 VM이상이 발견되면 가이드에 따라 복구합니다. 가이드: https://bosh.io/docs/cck/ 를 참조합니다.
```
ubuntu@opsmanager-2-4:~$ bosh -d  pivotal-container-service-182dfebc12215814ec6d cloud-check 
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

4. VM 중지.

- bosh deployment 목록 추출.
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name
```

-  모든 VM  중지 및 VM 삭제
bosh -d MY-DEPLOYMENT stop --hard
'--hard' 옵션은 VM을 삭제하지만 영구 디스크는 보존됩니다.
```
bosh -d service-instance_2f16abef-a827-4e35-af6d-6b169b607eda stop --hard

```

## PKS 기동 순서

1. opsmanager vm에 ssh 접속
2. bosh deployment 목록 추출.
3. deployment별로 중지를 합니다. 
- harbor
- PKS
- Kubernetes cluster
-  ...
4. deployment별로 상태점검


#### 1. PKS VM 기동 
1. bosh deployment 목록 추출.
```
ubuntu@opsmanager-2-4:~$ bosh deployments --column=name

```
2. 모든 vm 기동
```
bosh -d MY-DEPLOYMENT start

bosh -d service-instance_2f16abef-a827-4e35-af6d-6b169b607eda start

```

3. PKS VM의 상태를 확인합니다. 
- bosh vms의 결과에서 vm의 상태가 "running"이어야합니다.
```
ubuntu@opsmanager-2-4:~$ bosh -d service-instance_2f16abef-a827-4e35-af6d-6b169b607eda vms
```

#### 2. deployment bosh resurrector check
아래 내용을 참고합니다.
- https://github.com/myminseok/pivotal-docs/blob/master/start_stop_pcf.md#2-pas-%EC%A0%90%EA%B2%80

#### 3. PKS API에 접속하기
Pks cli를 통해 PKS API서버에 접속하는 방법을 설명합니다. 
- 아래의 내용은 https://docs.pivotal.io/runtimes/pks/1-2/configure-api.html  에 근거합니다. 

1. PC 또는 Jumpbox VM에 접속.
2. pks cli download
- Pivnet의 Pivotal Container Service제품 경로에서 pks cli를  다운로드
- https://network.pivotal.io/products/pivotal-container-service

3.  pks api 서버에 로그인.
```
pks login -a PKS-API-URL --username PKS-USER --password PASS -k
또는
pks login -a PKS-API-URL --username PKS-USER --password PASS --ca-cert CERTIFICATE-PATH
-	PKS API URL:  Ops Manager > Pivotal Container Service tile > setting탭> PKS API > API Hostname (FQDN) api.kps.example.com (http제외)
-	PKS-USER: pks사용자 (앞 절에서 생성)
-	PASS: pks사용자 password (앞 절에서 생성)
-	CERTIFICATE-PATH: ops manager root CA(ops manager VM내 /var/tempest/workspaces/default/root_ca_certificate)  , 사설인증서 인경우 -k옵션을 대신 넣습니다.
```

4. pks cluster목록 조회
```
pks clusters

```
#### 4. kubernetes cluster 상태확인
1. PC 또는 Jumpbox VM에 접속.
2. pks cli 설치
3.  pks api 서버에 로그인.
4. pks cluster목록 조회
5. pks get-credentials <cluster name> 
6. kubectl cli 설치
7. kubectl cluster-info <cluster name> 
8. kubectl get pods


