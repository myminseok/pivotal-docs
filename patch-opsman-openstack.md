opsmanager 2.4에 내장된 openstack library를 opsmanager 2.5로 포팅하는 가이드입니다.

## opsmanager 2.4에 내장된 openstack library 추출

```
ssh -i jumpbox.pem ubuntu@OPSMAN2.4-IP

ubuntu@opsman-2.5:  sudo su

root@opsman-2.4: cd /home/tempest-web/tempest/web/vendor/bundle/ruby/2.4.0/gems

root@opsman-2.4: ls -ald fog*
drwxrwxr-x 5 tempest-web tempest-web 4096 Jul 31 22:35 fog-aws-1.3.0
drwxrwxr-x 4 tempest-web tempest-web 4096 Jul 31 22:35 fog-core-1.44.3
drwxrwxr-x 7 tempest-web tempest-web 4096 Jul 31 22:35 fog-google-0.5.3
drwxrwxr-x 5 tempest-web tempest-web 4096 Jul 31 22:35 fog-json-1.0.2
drwxrwxr-x 4 tempest-web tempest-web 4096 Jul 31 22:35 fog-local-0.3.1
drwxrwxr-x 7 tempest-web tempest-web 4096 Jul 31 22:35 fog-openstack-0.1.22
drwxrwxr-x 5 tempest-web tempest-web 4096 Jul 31 22:35 fog-vsphere-1.2.2
drwxrwxr-x 5 tempest-web tempest-web 4096 Jul 31 22:35 fog-xml-0.1.3

root@opsman-2.4:  tar zcf opsman2.4-fog.tar.gz fog*

root@opsman-2.4: mv opsman2.4-fog.tar.gz /home/ubuntu/

root@opsman-2.4: cd /home/tempest-web/tempest/web/vendor/bundle/ruby/2.4.0/specifications

root@opsman-2.4: ls -ald fog*
-rw-rw-r-- 1 tempest-web tempest-web 2474 Jul 31 22:35 fog-aws-1.3.0.gemspec
-rw-rw-r-- 1 tempest-web tempest-web 3030 Jul 31 22:35 fog-core-1.44.3.gemspec
-rw-rw-r-- 1 tempest-web tempest-web 3460 Jul 31 22:35 fog-google-0.5.3.gemspec
-rw-rw-r-- 1 tempest-web tempest-web 1944 Jul 31 22:35 fog-json-1.0.2.gemspec
-rw-rw-r-- 1 tempest-web tempest-web 1770 Jul 31 22:35 fog-local-0.3.1.gemspec
-rw-rw-r-- 1 tempest-web tempest-web 3211 Jul 31 22:35 fog-openstack-0.1.22.gemspec
-rw-rw-r-- 1 tempest-web tempest-web 2440 Jul 31 22:35 fog-vsphere-1.2.2.gemspec
-rw-rw-r-- 1 tempest-web tempest-web 2283 Jul 31 22:35 fog-xml-0.1.3.gemspec

root@opsman-2.4: tar zcf opsman2.4-fog-spec.tar.gz fog*

root@opsman-2.4: mv opsman2.4-fog-spec.tar.gz /home/ubuntu/

root@opsman-2.4: cp /home/tempest-web/tempest/web/Gemfile.lock /home/ubuntu/opsman2.4-Gemfile.lock
```

### 아래 파일을 opsmanager 2.5의 /home/ubuntu아래에 복사합니다.
```
/home/ubuntu/opsman2.4-fog.tar.gz
/home/ubuntu/opsman2.4-fog-spec.tar.gz
/home/ubuntu/opsman2.4-Gemfile.lock
```

## opsmanager 2.5에 openstack library 포팅
#### opsman 2.5 VM 생성

#### Bosh CPI 패치
```
cp -a /var/tempest/internal_releases/cpi /var/tempest/internal_releases/cpi.bak
# cp -a /tmp/cpi-tc.tgz /var/tempest/internal_releases/cpi
# chown tempest-web:tempest-web /var/tempest/internal_releases/cpi

```
### vm type변경
```
# vim /home/tempest-web/tempest/web/app/models/persistence/models/openstack/openstack_infrastructure.rb

SUPPORTED_VM_TYPES = [
    VmType.new(name: 'm2.c1m2', ram: (1 * 1024), cpu: 1, ephemeral_disk: (20 * 1024)).freeze,
    VmType.new(name: 'm2.c1m2', ram: (2 * 1024), cpu: 1, ephemeral_disk: (20 * 1024)).freeze,
    VmType.new(name: 'm2.c2m4', ram: (4 * 1024), cpu: 2, ephemeral_disk: (40 * 1024)).freeze,
    VmType.new(name: 'm2.c4m8', ram: (8 * 1024), cpu: 4, ephemeral_disk: (80 * 1024)).freeze,
    VmType.new(name: 'm2.c8m16', ram: (16 * 1024), cpu: 8, ephemeral_disk: (160 * 1024)).freeze,
    VmType.new(name: 'm2.c16m32', ram: (32 * 1024), cpu: 16, ephemeral_disk: (160 * 1024)).freeze,
]

```
### opemsnager 2.4에서 추출한 openstack library교체
```
ssh -i jumpbox.pem ubuntu@OPSMAN2.5-IP

ubuntu@opsman-2.5: ls -al /home/ubuntu/
opsman2.4-fog.tar.gz
opsman2.4-fog-spec.tar.gz
opsman2.4-Gemfile.lock


ubuntu@opsman-2.5:  sudo su


root@opsman-2.5:  cd /home/tempest-web/tempest/web/vendor/bundle/ruby/2.4.0/gems
root@opsman-2.5:  tar zcf opsman2.5-fog.tar.gz fog*
root@opsman-2.5:  rm -rf fog*
root@opsman-2.5:  tar xvf /home/ubuntu/opsman2.4-fog.tar.gz


root@opsman-2.5: cp /home/tempest-web/tempest/web/Gemfile.lock /home/tempest-web/tempest/web/Gemfile.lock.orig

root@opsman-2.5: vi /home/tempest-web/tempest/web/Gemfile.lock

## 216라인부터 243라인까지 아래 내용으로 덮어씁니다. /home/ubuntu/opsman2.4-Gemfile.lock 참조

    fog-aws (1.3.0)
      fog-core (~> 1.38)
      fog-json (~> 1.0)
      fog-xml (~> 0.1)
      ipaddress (~> 0.8)
    fog-core (1.44.3)
      builder
      excon (~> 0.49)
      formatador (~> 0.2)
    fog-google (0.5.3)
      fog-core
      fog-json
      fog-xml
    fog-json (1.0.2)
      fog-core (~> 1.0)
      multi_json (~> 1.10)
    fog-local (0.3.1)
      fog-core (~> 1.27)
    fog-openstack (0.1.22)
      fog-core (>= 1.40)
      fog-json (>= 1.0)
      ipaddress (>= 0.8)
    fog-vsphere (1.2.2)
      fog-core
      rbvmomi (~> 1.9)
    fog-xml (0.1.3)
      fog-core
      nokogiri (>= 1.5.11, < 2.0.0)


root@opsman-2.5: service tempest-web restart

```

