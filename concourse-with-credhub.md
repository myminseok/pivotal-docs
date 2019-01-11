
control-plane에서 사용할 concourse를 설치할 것입니다.
- https://github.com/concourse/concourse-bosh-deployment/
- https://github.com/cloudfoundry-incubator/credhub-cli/releases
- https://github.com/pivotalservices/concourse-credhub
- https://github.com/pivotal-cf/pcf-pipelines/tree/master/docs/samples/colocated-credhub-ops
- https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/samples/concourse-with-credhub.yml
- https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/credhub-integration.md



## bbl env 로딩
이 작업은 jumpbox에서 실행합니다.따라서 jumpbox에서 bbl환경정보가 로딩되어있어야합니다. 
[bbl env 로딩](bbl.md#bbl-env-%EB%A1%9C%EB%94%A9)을 참고합니다.

## git cli설치
https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

## concourse deployment script 복제
임의의 경로에 폴더를 생성하고 다음 명령을 실행합니다.
~~~
git clone https://github.com/concourse/concourse-bosh-deployment

# 고가용성을 위해 cluster형태로 설치할 것입니다.
cd concourse-bosh-deployment/cluster
~~~

실제 수정된 샘플은 https://github.com/myminseok/concourse-bosh-deployment-v4.2.1 를 참조합니다.


# concourse 설치하기

## colocate concourse-web-credhub연동버전

### aws

```
# bbl 설치 폴더로 이동
eval "$(bbl print-env)"

git clone https://github.com/concourse/concourse-bosh-deployment

cd /workspace/dojo-concourse-bosh-deployment/cluster/

cd /workspace/dojo-concourse-bosh-deployment/cluster/operations/
wget https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/operations/add-credhub-uaa-to-web.yml

공인인증서가 없으면 concourse pipeline돌릴때 에러나므로 operations/credhub.yml파일에 insecure_skip_verify 옵션추가
위치 참조용 release spec

# 하기 내용으로 수정
- type: replace
  path: /instance_groups/name=web/jobs/name=atc/properties/credhub?
  value:
    url: ((credhub_url))
    client_id: ((credhub_client_id))
    client_secret: ((credhub_client_secret))
    tls:
      ca_cert:
        certificate: ((credhub_ca_cert))
      insecure_skip_verify: true
      
      
      
# (필요시) bosh에 worker vm type추가 

/workspace/dojo-concourse-bosh-deployment/cluster$ bosh cloud-config > bosh-cloud-config.yml
vi bosh-cloud-config.yml

vm_types:
- cloud_properties:
    ephemeral_disk:
      size: 102400
      type: gp2
    instance_type: m4.large
  name: disk_100G_type

-  ~/workspace/dojo-concourse-bosh-deployment/cluster$ bosh update-cloud-config ./bosh-cloud-config.yml



# concourse-bosh-deployment/cluster 폴더로 이동
설정파일 생성
https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/concourse.md


cd concourse-bosh-deployment/cluster
wget https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/versions.yml 
cat versions.yml  >> ../versions.yml

https://bosh.io/stemcells/
bosh upload-stemcell --sha1 c8b65794ca4c45773b6fe23b3d447dde520f07b0 \
  https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent?v=170.3
  


vi deploy-concourse.sh

export concourse_elb=xxxx
bosh deploy -n --no-redact -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store cluster-creds.yml \ <=== remove this to store into bosh credhub.
  -o operations/basic-auth.yml \
  -o operations/privileged-http.yml \
  -o operations/privileged-https.yml \
  -o operations/tls.yml \
  -o operations/tls-vars.yml \
  -o operations/scale.yml \
  -o operations/worker-ephemeral-disk.yml \
  -o operations/add-credhub-uaa-to-web.yml \
  -o operations/container-placement-strategy-random.yml \
  -o operations/web-network-extension.yml \
  --var web_network_name=private \
  --var web_network_vm_extension=lb \
  --var network_name=private \
  --var external_host=$concourse_elb \
  --var external_url=https://$concourse_elb \
  --var external_lb_common_name=$concourse_elb \
  --var concourse_host=$concourse_elb \
  --var web_vm_type=default \
  --var worker_ephemeral_disk=100GB_ephemeral_disk \
  --var worker_vm_type=default \
  --var db_vm_type=default \
  --var db_persistent_disk_type=10GB \
  --var web_instances=1 \
  --var worker_instances=1 \
  --var deployment_name=concourse \
  --var local_user.username= \
  --var local_user.password= 



./deploy-concourse.sh

```


# test concourse

```
wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.1.0/credhub-linux-2.1.0.tgz

wget  https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/target-concourse-credhub.sh

bbl lbs

export CONCOURSE_URL=https://<concourse -lb-url>
source ./target-concourse-credhub.sh

$ crehub api
# credhub set -t value -n /concourse/main/test/hello -v test

$ credhub get -n /concourse/main/test/hello
id: 3cd51b78-426f-4145-b94e-baacf16c383d
name: /concourse/main/test/hello
type: value
value: test

```


###  set env.
```
vi ~/.profile.sh

pushd .
cd ~/workspace/bbl
eval "$(bbl print-env)"
popd

source ~/workspace/concourse-bosh-deployment/cluster/target-concourse-credhub.sh

```


  
  
## bosh-credhub연동버전

###  bosh deployment script 준비

#### concourse v3.14.1.0 on aws 

반복하여 실행해야 하므로 아래 내용으로 deploy.sh스크립트를 생성합니다. 
~~~
export concourse_elb=<bbl lbs명령으로 추출한 concourse elb url>

bosh deploy -n --no-redact -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store cluster-creds.yml \
  -o operations/basic-auth.yml \
  -o operations/privileged-http.yml \
  -o operations/privileged-https.yml \
  -o operations/tls.yml \
  -o operations/tls-vars.yml \
  -o operations/web-network-extension.yml \
  -o operations/scale.yml \
  -o operations/static-db.yml \
  -o operations/worker-ephemeral-disk.yml \
  -o operations/credhub.yml \
  --var network_name=private \
  --var external_host=$concourse_elb \
  --var external_url=https://$concourse_elb \
  --var web_vm_type=default \
  --var db_vm_type=default \
  --var db_persistent_disk_type=10GB \
  --var worker_ephemeral_disk=100GB_ephemeral_disk \
  --var worker_vm_type=default \
  --var web_instances=1 \
  --var worker_instances=1 \
  --var deployment_name=concourse \
  --var web_network_name=private \
  --var web_network_vm_extension=lb \
  --var local_user.username=admin \
  --var local_user.password=<비밀번호> \
  --var atc_basic_auth.username=admin \
  --var atc_basic_auth.password=<비밀번호> \
  --var external_lb_common_name=$concourse_elb \
  --var concourse_host=$concourse_elb \
  --var db_ip=10.0.31.190 \
  --var credhub_url=https://10.0.0.6:8844 \
  --var credhub_client_id=concourse_to_credhub \
  --var credhub_client_secret=<비밀번호> \
  -l ./credhub_ca.ca


  
  # worker_ephemeral_disk: bosh cloud-config에서 나온 값을 입력
  # db_ip: bosh cloud-config에서 나온 private network의 값중 static_ip의 pool에서 하나를 선택.
  # credhub_url: bbl director-address
  # credhub_client_id, credhub_client_secret: 앞에서 추가한 사용자정보
  # credhub_ca.ca파일:
    bbl 설치 폴더로 이동
    eval "$(bbl print-env)"
    bosh int ./vars/director_vars_stores.yml --path /credhub_ca/ca > credhub_ca.ca
    위 명령으로 credhub인증서를 추출한 후 아래 포맷으로 credhub_ca.ca 파일에 저장.
    credhub_ca_cert: |
      ----- BEGIN xxx-----
      xxxx
      ---- END xxx-----
    chmod 600 credhub_ca.ca 
~~~


#### concourse 4.1.0 on vsphere 
~~~
export concourse_url=https://<concourse url>

bosh -e d deploy -n --no-redact -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store cluster-creds.yml \
  -o operations/basic-auth.yml \
  -o operations/privileged-http.yml \
  -o operations/privileged-https.yml \
  -o operations/tls.yml \
  -o operations/tls-vars.yml \
  -o operations/scale.yml \
  -o operations/static-web.yml \
  -o operations/cf-auth.yml \
  --var web_ip=10.10.10.210 \
  --var network_name=concourse \
  --var external_url=https://<concourse url> \
  --var web_vm_type=medium \
  --var db_vm_type=medium.disk \
  --var worker_vm_type=large.disk \
  --var db_persistent_disk_type=db \
  --var web_instances=1 \
  --var worker_instances=1 \
  --var deployment_name=concourse \
  --var external_lb_common_name=<concourse url> \
  --var external_host=<concourse url> \
  --var concourse_host=<concourse url> \
  --var local_user.username=admin \
  --var local_user.password=<password>

~~~


  
  
### 배포된 concourse를 삭제하려면
~~~
# bbl 설치 폴더로 이동
eval "$(bbl print-env)"

bosh delete-deployment -d concourse
~~~

### worker vm만 다시 만들려면

~~~
# bbl 설치 폴더로 이동
eval "$(bbl print-env)"

bosh -d concourse recreate worker
~~~



## concourse사용하기.

### fly cli설치
~~~
fly client download(linux):
wget https://github.com/concourse/concourse/releases/download/v4.2.1/fly_linux_amd64
~~~

### fly login

~~~
fly -t sandbox login -c <concourse elb url> -u <concourse설치시 지정한 user id> -p <concourse설치시 지정한 password> -k

fly targets

fly -t sandbox status

fly -t sandbox workers
=> worker 목록이 나오면 정상로그인된 것임.

~~~

### concourse credhub test sample pipeline


```
wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.1.0/credhub-linux-2.1.0.tgz

wget  https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/target-concourse-credhub.sh

export CONCOURSE_URL=https://<concourse -lb-url>
source ./target-concourse-credhub.sh

$ crehub api
# credhub set -t value -n /concourse/main/test/hello -v test

$ credhub get -n /concourse/main/test/hello
id: 3cd51b78-426f-4145-b94e-baacf16c383d
name: /concourse/main/test/hello
type: value
value: test

```

https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/credhub-integration.md#sample-pipeline

https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/samples/hello-credhub.yml
~~~
jobs:
- name: hello-credhub
  plan:
  - do:
    - task: hello-credhub
      config:
        platform: linux
        image_resource:
          type: docker-image
          source:
            repository: ubuntu
        run:
          path: sh
          args:
          - -exc
          - |
            echo "Hello $WORLD_PARAM"
      params:
        WORLD_PARAM: {{hello}}
  ~~~
  
 ~~~
 fly -t sandbox sp -p hello-credhub -c ./hello-credhub.yml
 fly -t sandbox up -p hello-credhub 
 
 ~~~
 
 웹브라우져로 확인.

## PAS의 사용자를 concourse에 연동하기
 - [PAS의 사용자 인증을 통해 concourse로그인하도록 설정하기](concourse_with_cf_auth.md)

 
 
 

  
  
