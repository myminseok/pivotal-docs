Local PC에 bbl을 위한 환경을 설정하는 것을 설명합니다.
참고 문서: https://github.com/cloudfoundry/bosh-bootloader

## aws cli 설치 
https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/getting-started-aws.md

## bbl 및 bosh cli설치
mac기준입니다.
~~~
brew tap cloudfoundry/tap
brew install bosh-cli
brew install bbl
~~~

## aws 상에 IAM사용자를 생성
사용자는 aws console또는 shell상에서 만들수 있습니다.
사용자의 권하는 자동화의 범위에 따라서 튜닝해주어야합니다.
참고 문서: https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/getting-started-aws.md

~~~
aws iam create-user --user-name "bbl-user"
aws iam put-user-policy --user-name "bbl-user" \
--policy-name "bbl-policy" \
--policy-document "$(pbpaste)"
aws iam create-access-key --user-name "bbl-user"
~~~


## concourse terraform 수정
https://github.com/pivotalservices/concourse-credhub/tree/master/bbl-terraform/

```
cd <BBL_WORK_FOLDER>/terraform/
wget https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/bbl-terraform/aws/concourse-lb_override.tf
```

## bbl up
bbl up명령으로 aws상에 설정을 생성합니다. 다음 명령은 vpc, security group, nat VM, concourse용 load balancer,  jumpbox, bosh direcor vm 등을 생성합니다.

* 임의의 경로에 폴더를 생성하고 다음 명령을 실행합니다.
~~~
bbl up \
	--aws-access-key-id <INSERT ACCESS KEY ID> \
	--aws-secret-access-key <INSERT SECRET ACCESS KEY> \
	--aws-region ap-northeast-2 \
	--iaas aws \
  --lb-type concourse
~~~
* bbl env 로딩
bbl up을 실행한 폴더에 가서 아래 명령을 실행하면 bbl의 환경변수정보가 로딩되어 bbl, bosh명령을 사용할 수 있게 됩니다.

```
eval "$(bbl print-env)"
```


# bbl customizing

## jumpbox디스크 용량 증설
jumpbox의 기본 디스크 용량은 20GB입니다. 증설하려면 다음 설정을 추가하고 bbl up명령을 실행합니다.

### bbl 명령을 실행할 임의의 경로에 폴더를 생성합니다.
mkdir <BBL_WORK_FOLDER>

### <BBL_WORK_FOLDER>/create-jumpbox-override.sh파일을 생성합니다.
~~~
#!/bin/sh
bosh create-env \
  ${BBL_STATE_DIR}/jumpbox-deployment/jumpbox.yml \
  --state  ${BBL_STATE_DIR}/vars/jumpbox-state.json \
  --vars-store  ${BBL_STATE_DIR}/vars/jumpbox-vars-store.yml \
  --vars-file  ${BBL_STATE_DIR}/vars/jumpbox-vars-file.yml \
  -o  ${BBL_STATE_DIR}/jumpbox-deployment/aws/cpi.yml \
  -o  ${BBL_STATE_DIR}/ops-override/jumpbox-disk-cpi.yml \
  -v  access_key_id="${BBL_AWS_ACCESS_KEY_ID}" \
  -v  secret_access_key="${BBL_AWS_SECRET_ACCESS_KEY}" 
~~~

ops-override폴더를 만들고 jumpbox-disk-cpi.yml을 생성합니다.
50GB의 디스크를 가진 jumpbox설정입니다.
vi <BBL_WORK_FOLDER>/ops-override/jumpbox-disk-cpi.yml
~~~
# Configure AWS sizes
- type: replace
  path: /resource_pools/name=vms/cloud_properties?
  value:
    instance_type: t2.micro
    ephemeral_disk: {size: 50_000, type: gp2}
    availability_zone: ((az))

~~~


* <BBL_WORK_FOLDER>에서 bbl up 명령을 실행하면 50GB의 디스크를 가진 jumpbox가 생성됩니다.

## jumpbox OS 교체

<BBL_WORK_FOLDER>/ops-override/jumpbox-xenial.cpi.yml
~~~
- type: replace
  path: /resource_pools/name=vms/stemcell?
  value:
    url:  https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent?v=97.18
    sha1: 21fcaed3208f9450032a7fc31acc954a3f70fb13
~~~

* <BBL_WORK_FOLDER>/create-jumpbox-override.sh파일을 생성합니다.
~~~
#!/bin/sh
bosh create-env \
  ${BBL_STATE_DIR}/jumpbox-deployment/jumpbox.yml \
  --state  ${BBL_STATE_DIR}/vars/jumpbox-state.json \
  --vars-store  ${BBL_STATE_DIR}/vars/jumpbox-vars-store.yml \
  --vars-file  ${BBL_STATE_DIR}/vars/jumpbox-vars-file.yml \
  -o  ${BBL_STATE_DIR}/jumpbox-deployment/aws/cpi.yml \
  -o  ${BBL_STATE_DIR}/ops-override/jumpbox-disk-cpi.yml \
  -o  ${BBL_STATE_DIR}/ops-override/jumpbox-xenial.cpi.yml \
  -v  access_key_id="${BBL_AWS_ACCESS_KEY_ID}" \
  -v  secret_access_key="${BBL_AWS_SECRET_ACCESS_KEY}" 
~~~


참고: https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/advanced-configuration.md
참고: https://github.com/myminseok/bbl-template


