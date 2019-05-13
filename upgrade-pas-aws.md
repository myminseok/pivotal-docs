## PAS Major 업그레이드 순서
PAS에서 Major업그레이드는 2.3.x -> 2.4.x로 업그레이드하는 것을 말합니다.
https://docs.pivotal.io/pivotalcf/2-5/customizing/upgrading-pcf.html#prepare

### 사전점검
https://docs.pivotal.io/pivotalcf/2-3/upgrading/checklist.html

1. Platform 정합성 점검 
- opsman UI
- bosh instances
- bosh cck
2. PCF 백업
- opsman export
- bbr director
- bbr PAS
3. 릴리즈 노트 확인
4. Tile 호환성 확인 & 업그레이드
- https://docs.pivotal.io/resources/product-compatibility-matrix.pdf
- 서비스 타일내에서 업그레이드 순서를 반드시 지켜야합니다.: 예) PCC 1.4.1+ -> 1.5.1+ -> 1.6.1+
- tile의 settings탭의 errand에서 upgrade instance옵션이  활성화합니다.
- tile별로 하나씩 업그레이드하고 apply change를 합니다.(한꺼번에 여러 tile을 갱신하는 것은 관리상 좋지 않습니다.)
5. PCF 백업
- opsman export
- bbr director
- bbr PAS
6. 플랫폼 용량점검
- cell VM
- bosh clean-up 
7. Ops Manager 업그레이드
- 기존 opsman shutdown
- 새로운 opsman vm 생성: 예) 2.3.x -> 2.4.x
8. opsmanager settings 임포트 & apply change
9. Platform 정합성 점검 
- opsman UI
- bosh instances
- bosh cck
- PAS DB
10. PCF 백업
- opsman export
11. PAS upgrade
- 2.3.x -> 2.4.x
12. bosh clean-up 
13. PCF 백업
- opsman export
- bbr director
- bbr PAS

파이프라인을 구성하는 방법을 설명합니다.
![image](https://github.com/myminseok/pivotal-docs/blob/master/upgrade-pas/newopsman-import-old-pas.png)
![image](https://github.com/myminseok/pivotal-docs/blob/master/upgrade-pas/concourse-pipeline-upgrade-opsman.png)

## PAS 업그레이드 파이프라인 구성
1. Ops Manager 업그레이드 파이프라인

### PCF 파이프라인 다운로드
```
https://github.com/pivotal-cf/pcf-pipelines
github clone https://github.com/pivotal-cf/pcf-pipelines.git
```
### params.yml 수정
```
# Existing Ops Manager VM name pattern. This should uniquely filter to a running
# eg.  myenv-OpsMan
existing_opsman_vm_name: jygal-OpsMan az1

# Optional - if your git repo requires an SSH key.
git_private_key: ((git_private_mega_key.private_key))

# Ops Manager Admin Credentials - set during the installation of Ops Manager
# Either opsman_client_id/opsman_client_secret or opsman_admin_username/opsman_a
# If you are using opsman_admin_username/opsman_admin_password, edit opsman_clie
# If you are using opsman_client_id/opsman_client_secret, edit opsman_admin_user
opsman_client_id:
opsman_client_secret:
opsman_admin_username: ((opsman_admin.username))
opsman_admin_password: ((opsman_admin.password))

# If install pipeline has been used then the passphrase is same as the admin pas
opsman_passphrase: ((opsman_admin.password))

# Ops Manager Url - FQDN to access Ops Manager without protocol (will use https)
opsman_domain_or_ip_address: opsman.sampivotal.com

opsman_major_minor_version: ^2\.3\.[0-9]+$ # Ops Manager minor version to track

# Pivotal Net Token to download Ops Manager binaries from https://network.pivota
pivnet_token: ((pivnet_token)) # value must be a Pivotal Network legacy token; U

# AWS params
aws_access_key_id: ((aws_access_key_id))
aws_secret_access_key: ((aws_secret_access_key))
aws_region: ap-northeast-2
aws_vpc_id: vpc-xxxxxxxx

```
### 파이프라인 배포
```
/workspace/pcf-pipelines/upgrade-ops-manager/aws$ fly -t concourse sp -p upgrade-ops-manager -c pipeline.yml -l params.yml
```

2. PAS 업그레이드 파이프라인
### params.yml 수정
```
# Set to true to enable all errands, false to disable all or leave blank to keep states the same.
enable_errands: true

# The IaaS name for which stemcell to download. This must match the IaaS name
# within the stemcell to download, e.g. "vsphere", "aws", "azure", "google" must be lowercase.
iaas_type: aws

git_private_key: ((git_private_key_credhub.private_key))

# Operations Manager
# ------------------------------
# Credentials for Operations Manager. These are used for uploading, staging,
# and deploying the product file on Operations Manager.
# Either opsman_client_id/opsman_client_secret or opsman_admin_username/opsman_admin_password needs to be specified.
# If you are using opsman_admin_username/opsman_admin_password, edit opsman_client_id/opsman_client_secret to be an empty value.
# If you are using opsman_client_id/opsman_client_secret, edit opsman_admin_username/opsman_admin_password to be an empty value.
opsman_admin_username: ((opsman_admin.username))
opsman_admin_password: ((opsman_admin.password))
opsman_client_id:
opsman_client_secret:
opsman_domain_or_ip_address: opsman.<yourdomain>

# Resource
# ------------------------------
# The token used to download the product file from Pivotal Network. Find this
# on your Pivotal Network profile page:
# https://network.pivotal.io/users/dashboard/edit-profile
pivnet_token: ((pivnet_token))

# The globs regular expression for the PivNet resource to download the product
# release files. "*pivotal" is the default.
# For products such as ERT, it is recommended to use "cf*pivotal" to avoid the
# extra download of the SRT file in PCF 1.12.*
product_globs: "cf*pivotal"

# om-linux
# ------------------------------
# The name of the product on Pivotal Network. This is used to configure the
# resource that will fetch the product file.
#
# This can be found in the URL of the product page, e.g. for rabbitmq the URL
# is https://network.pivotal.io/products/pivotal-rabbitmq-service, and the
# product slug is 'pivotal-rabbitmq-service'.
product_slug: elastic-runtime

# The minor product version to track, as a regexp. To track 1.11.x of a product, this would be "^2\.1\.[0-9]+$", as shown below.
product_version_regex: ^2\.3\.[0-9]+$

```
### 파이프라인 배포
```
/workspace/pcf-pipelines/upgrade-tile$ fly -t concourse sp -p upgrade-pas -c pipeline.yml -l params.yml
```



