
# BOSH로 배포한 VM의 설정을 일괄로 변경하기
이 문서는 BOSH로 배포한 VM에 공통 패키지 설치, OS설정 변경등의 작업(add-on)을 일괄로 관리할 수 있게하는 방법에 대해 설명합니다.
이 기능은 기본적으로 BOSH의 runtime-config 기능을 사용하는 것입니다. 자세한 사항은 https://bosh.io/docs/runtime-config/를 참고하세요.
기본으로 제공하는 add-on은 https://bosh.io/docs/addons-common/ 를 참고하세요.

## ulimit설정 변경 예시


### ulimit release업로드
ulimit을 변경하는 addon release를 만들어야합니다. 이 경우는 미리 만들어진 https://github.com/pivotal-cf/ulimit-release 를 사용하겠습니다.

```
wget https://github.com/pivotal-cf/ulimit-release/releases/download/v1/ulimit.tgz

$ bosh upload-release ulimit.tgz

#업로드 확인
$ bosh releases
Name                    Version  Commit Hash
ulimit                  1*       8691641

(*) Currently deployed
(+) Uncommitted changes

1 releases

Succeeded

```


###  runtime-config파일 준비합니다.
아래와 같은 파일을 생성합니다.

vi ulimit-runtime-config.yml

```
releases:
- name: ulimit
  version: 1

addons:
- name: ulimit-addon
  jobs:
  - name: ulimit
    release: ulimit
  properties:
    nofile:
      soft: 32768  
      hard: 32768
#  include:
#    deployments:
#    - concourse
```


! 주의사항은  nofile 설정값을 32768 이하로 설정하세요.이 값은 linux system 설정인 RLIMIT_NOFILE값을 따릅니다.
이 값을 변경하려면 ulimit release를 수정하여 패키징합니다. 수정할 곳은 https://github.com/pivotal-cf/ulimit-release/blob/master/src/pivotal_prlimit/pivotal_prlimit.c 입니다.

! release version은 위의 bosh releases 명령의 결과에 맞춰주세요.


###  bosh의 runtime-config를 갱신합니다.

```
$ bosh update-runtime-config ./ulimit-runtime-config.yml

# 갱신내용을 확인합니다.
$ bosh runtime-config
Using environment '10.10.10.200' as client 'admin'

addons:
- jobs:
  - name: ulimit
    release: ulimit
  name: ulimit-addon
  properties:
    nofile:
      hard: 32768
      soft: 32768
releases:
- name: ulimit
  version: 1

Succeeded
```

### deployment 다시 배포하기.
addon을 적용할 deployment를 다시 배포하면 addon이 적용되면서 다시 생성됩니다.

```
$ ./deploy-vsphere.sh
Using environment '10.10.10.200' as client 'admin'

Using deployment 'concourse'

Release 'postgres/30' already exists.

Release 'concourse/4.2.1' already exists.

Release 'garden-runc/1.16.3' already exists.

  vm_types:
+ - cloud_properties:
+     cpu: 1
+     disk: 2024
+     ram: 1024
+   name: default

  releases:
+ - name: ulimit
+   version: '1'

+ addons:
+ - jobs:
+   - name: ulimit
+     release: ulimit
+   name: ulimit-addon
+   properties:
+     nofile:
+       hard: 32768
+       soft: 32768
Task 628

Task 628 | 14:32:13 | Preparing deployment: Preparing deployment (00:00:01)
Task 628 | 14:32:15 | Preparing package compilation: Finding packages to compile (00:00:00)
Task 628 | 14:32:15 | Updating instance db: db/ca1c5383-b8fd-4925-915d-cdc62d36a995 (0) (canary)
Task 628 | 14:32:15 | Updating instance web: web/928d0c17-663c-41a1-b4ca-c5039140335e (0) (canary)
Task 628 | 14:32:15 | Updating instance worker: worker/0fea7ea7-f87b-4547-9cd1-00590bcd727a (0) (canary)
Task 628 | 14:32:40 | Updating instance web: web/928d0c17-663c-41a1-b4ca-c5039140335e (0) (canary) (00:00:25)
Task 628 | 14:32:41 | Updating instance worker: worker/0fea7ea7-f87b-4547-9cd1-00590bcd727a (0) (canary) (00:00:26)
Task 628 | 14:32:47 | Updating instance db: db/ca1c5383-b8fd-4925-915d-cdc62d36a995 (0) (canary) (00:00:32)

Task 628 Started  Mon Jan  7 14:32:13 UTC 2019
Task 628 Finished Mon Jan  7 14:32:47 UTC 2019
Task 628 Duration 00:00:34
Task 628 done

Succeeded


```

### 변경 내용 확인하기

```
pivotal@ubuntu:~/concourse-bosh-deployment-aws/cluster$ bosh -d concourse ssh web
Using environment '10.10.10.200' as client 'admin'

web/928d0c17-663c-41a1-b4ca-c5039140335e:~$ ulimit -n
32768

```
