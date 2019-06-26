## Deploy Harbor via BOSH

- https://github.com/vmware/harbor-boshrelease

### Download 
```
as ubuntu
git clone git@github.com:vmware/harbor-boshrelease.git

wget -O harbor-boshrelease.git.zip  https://github.com/vmware/harbor-boshrelease/archive/master.zip

wget -O harbor.release-1.7.5-build.10 https://bosh.io/d/github.com/vmware/harbor-boshrelease?v=1.7.5-build.10

wget -O ubuntu.xenial  https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-xenial-go_agent?v=250.29

wget -O bosh-dns-release.0.1.3 https://bosh.io/d/github.com/cloudfoundry/bosh-dns-release?v=0.1.3


```


### vi manifests/runtime-config-bosh-dns.yml
- include, exclude 설명 참고: https://bosh.io/docs/runtime-config/

```
addons:
- include:
    deployments:
    - harbor-deployment
  exclude:
    deployments:
    - minio
  jobs:
```

```
bosh -n update-runtime-config manifests/runtime-config-bosh-dns.yml 
bosh  runtime-config

```


## /manifests/harbor.yml

- release : delete url, hash 
- stemcell: version -> latest
- deployment-network -> your network in cloud-config
- az -> your az in cloud config
- 필요시 deployment명 수정. 이때 addons.jobs.properties.aliaes도 수정해야함.
- Fix smoke test failure in bosh release:

```
instance_groups:
- name: harbor-app
  ...
  jobs:
  - name: harbor
    release: harbor-container-registry
    properties:
      admin_password_for_smoketest: ((harbor_admin_password_for_smoketest))

...

variables:
- name: harbor_admin_password_for_smoketest
  type: password

```

##  harbor 배포
```
bosh -n -d harbor-deployment deploy manifests/harbor.yml -v hostname=harbor.my.local
```


## harbor account

find in creds.yml
```
bosh int ./creds.yml --path /harbor_admin_password
xxxxxx

Succeeded
```
or

```
/var/vcap/jobs/harbor/config/harbor.cfg:harbor_admin_password = 
=> admin / xxxx


https://harbor.my.local/harbor/projects

```

# DNS

harbor.my.local -> harbor-app VM IP.


# 샘플 docker image ubuntu 업로드/다운로드 테스트

```
sudo su
docker pull ubuntu
docker save ubuntu.docker.image


sudo su

docker load -i ubuntu.docker.image
docker tag ubuntu harbor.my.local/dojo/ubuntu

https://docs.docker.com/registry/insecure/
cat /etc/docker/daemon.json 
{
  "insecure-registries" : ["harbor.my.local"]
}


vi /etc/hosts
<harbor IP> harbor.local 

systemctl restart docker.service

docker login harbor.my.local -u admin  -p xxxx

docker push harbor.my.local/dojo/ubuntu

docker pull harbor.my.local/dojo/ubuntu
docker images

```

