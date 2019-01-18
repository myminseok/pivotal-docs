
This document explains how to install concourse cluster.

## prerequisites.
- [Setting up jumpbox](setup-bbl-sandbox.md)

## reference documents
- https://github.com/concourse/concourse-bosh-deployment/
- https://github.com/cloudfoundry-incubator/credhub-cli/releases
- https://github.com/pivotalservices/concourse-credhub
- https://github.com/pivotal-cf/pcf-pipelines/tree/master/docs/samples/colocated-credhub-ops
- https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/samples/concourse-with-credhub.yml
- https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/credhub-integration.md

## loading bbl environment variables(jumpbox)

- [bbl(bosh-bootloader)-aws  ](bbl.md)
- [bbl-azure](bbl-azure.md)

## install git cli (jumpbox)
https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

## clone concourse bosh deployment 

```
mkdir ~/workspace/
cd workspace
git clone https://github.com/concourse/concourse-bosh-deployment

# we will install concourse 'cluster' for HA
cd concourse-bosh-deployment/cluster
```

reference:https://github.com/myminseok/concourse-bosh-deployment-v4.2.1


# install concourse cluster

## colocate credhub on concourse-web VM


```
# loading bbl environment variable 
cd ~/workspacce/bbl
eval "$(bbl print-env)"

# go to concourse-bosh-deployment directory
# git clone https://github.com/concourse/concourse-bosh-deployment
cd /workspace/dojo-concourse-bosh-deployment/cluster/

# add add-credhub-uaa-to-web.yml ops file
cd /workspace/dojo-concourse-bosh-deployment/cluster/operations/
wget https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/operations/add-credhub-uaa-to-web.yml

# modify operations/credhub.yml to disable ssl validation for private-certificate.
vi opera
tions/credhub.yml 

- type: replace
  path: /instance_groups/name=web/jobs/name=atc/properties/credhub?
  value:
    url: ((credhub_url))
    client_id: ((credhub_client_id))
    client_secret: ((credhub_client_secret))
    tls:
      ca_cert:
        certificate: ((credhub_ca_cert))
      insecure_skip_verify: true     <=====   disable ssl validation for private-certificate.
      
      
      
# (optional) check and update bosh vm types to bosh director vm.

/workspace/dojo-concourse-bosh-deployment/cluster$ bosh cloud-config > bosh-cloud-config.yml
vi bosh-cloud-config.yml

vm_types:
- cloud_properties:
    ephemeral_disk:
      size: 102400
      type: gp2
    instance_type: m4.large
  name: 100GB_ephemeral_disk

-  ~/workspace/dojo-concourse-bosh-deployment/cluster$ bosh update-cloud-config ./bosh-cloud-config.yml


# add credhub release version info 
cd concourse-bosh-deployment/cluster
wget https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/versions.yml 
cat versions.yml  >> ../versions.yml

# upload stemcell to bosh director vm.
https://bosh.io/stemcells/
bosh upload-stemcell --sha1 c8b65794ca4c45773b6fe23b3d447dde520f07b0 \
  https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent?v=170.3
  

# edit deploy script.

vi deploy-concourse.sh

export concourse_elb=xxxx <-- put dns or ip only (no https://)
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

$ credhub set -t value -n /concourse/main/test/hello -v test

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


  
  
## concourse and bosh-credhub

###  bosh deployment script 

#### concourse v3.14.1.0 on aws 

vi deploy.sh
~~~
export concourse_elb=<concourse elb url>

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


  
  
### delete bosh concourse deployment
~~~
# move to bbl direcftory
eval "$(bbl print-env)"

bosh delete-deployment -d concourse
~~~

### recreate worker vm

~~~
# move to bbl direcftory
eval "$(bbl print-env)"

bosh -d concourse recreate worker
~~~



## how to use concourse

### fly cli
~~~
fly client download(linux):
wget https://github.com/concourse/concourse/releases/download/v4.2.1/fly_linux_amd64
~~~

### fly login

~~~
fly -t sandbox login -c <concourse elb url> -u <concourse user id> -p <concourse password> -k

fly targets

fly -t sandbox status

fly -t sandbox workers


~~~

### concourse credhub test sample pipeline


```
wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.1.0/credhub-linux-2.1.0.tgz

wget  https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/target-concourse-credhub.sh

export CONCOURSE_URL=https://<concourse -lb-url>
source ./target-concourse-credhub.sh

$ credhub api

$ credhub set -t value -n /concourse/main/test/hello -v test

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
 
wheck with web browser

## bind concourse user with PAS UAA
- [bind users in concourse with PAS](concourse_with_cf_auth.md)

 
 
 

  
  
