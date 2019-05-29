# there are two jumpbox(internal, external)

# OS
- 16.04 LTS, 64 bit 
- http://releases.ubuntu.com/xenial/


# BOSH Cli env

## Download (External jumpbox)
https://bosh.io/docs/cli-v2-install/
```
wget https://github.com/cloudfoundry/bosh-cli/releases/download/v5.4.0/bosh-cli-5.4.0-linux-amd64
```

## BOSH dependency binaries Download
```
sudo su
mkdir bosh-binaries
cd bosh-binaries
apt-get download  build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3
```

## copy files from external jumpbox to internal jumpbox
```
tar zcf bosh-binaries.tar.gz ./bosh-binaries
scp bosh-binaries.tar.gz ubuntu@172.28.83.54:/home/ubuntu/bosh.tar.gz

tar xf bosh-binaries.tar.gz
cd bosh-binaries/apt/archives
dpkg -i *.deb
apt-get install -f
apt list --installed
```



# bosh dependency(external jumpbox)
- https://bosh.io/docs/init-vsphere/
- bosh create-env를 위한 의존성 바이너리를 내려받기위해 외부 점프박스에서 아래 명령을 수행한다.
```
apt download libcurl3
dpkg -i libcurl3_7.47.0-1ubuntu2.12_amd64.deb 
apt-get install -f

```

# bosh create-env dependency(external jumpbox)
```
as ubuntu
cd /home/ubuntu

mkdir bosh-1 && cd bosh-1
git clone https://github.com/cloudfoundry/bosh-deployment

ubuntu@external-jumpbox:~/bosh-1$ cat deploy.sh 
bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -o bosh-deployment/jumpbox-user.yml \
    -o bosh-deployment/uaa.yml \
    -o bosh-deployment/credhub.yml \
    -o bosh-deployment/misc/config-server.yml \
    -v director_name=bosh-1 \
    -v internal_cidr=192.168.0.0/24 \
    -v internal_gw=192.168.0.1 \
    -v internal_ip=192.168.0.10 \
    -v network_name="mgmt-network" \
    -v vcenter_dc=datacenter \
    -v vcenter_ds=PCF_Image \
    -v vcenter_ip=192.168.0.11 \
    -v vcenter_user=--- \
    -v vcenter_password=---- \
    -v vcenter_templates=bosh-1-templates \
    -v vcenter_vms=bosh-1-vms \
    -v vcenter_disks=bosh-1-disks \
    -v vcenter_cluster=cluster


cd /home/ubuntu

tar zcf bosh-cache.tar.gz .bosh
scp bosh-cache.tar.gz ubuntu@internal-jumpbox:/home/ubuntu

# internal jumpbox의 ubuntu계정 home 에서 압축해제 -> /home/ubuntu/.bosh 
tar xf bosh-cache.tar.gz
```


# deploy bosh director vm (internal jumpbox)

guide: https://bosh.io/docs/init-vsphere/
```

ubuntu@internal-jumpbox:~/bosh-1$ cat deploy.sh 
bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -o bosh-deployment/jumpbox-user.yml \
    -o bosh-deployment/uaa.yml \
    -o bosh-deployment/credhub.yml \
    -o bosh-deployment/misc/config-server.yml \
    -v director_name=bosh-1 \
    -v internal_cidr=192.168.0.0/24 \
    -v internal_gw=192.168.0.1 \
    -v internal_ip=192.168.0.10 \
    -v network_name="mgmt-network" \
    -v vcenter_dc=datacenter \
    -v vcenter_ds=PCF_Image \
    -v vcenter_ip=192.168.0.11 \
    -v vcenter_user=--- \
    -v vcenter_password=---- \
    -v vcenter_templates=bosh-1-templates \
    -v vcenter_vms=bosh-1-vms \
    -v vcenter_disks=bosh-1-disks \
    -v vcenter_cluster=cluster
```

# credhub test
```
# install client: 
 wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.4.0/credhub-linux-2.4.0.tgz
tar xf credhub-linux-2.4.0.tgz
mv credhub /usr/local/bin/credhub

# get credhub login secret
cd /home/ubuntu/bosh-1
grep credhub ./creds.yml


# credhub login script
ubuntu@internal-jumpbox:~/bosh-3$ cat login-credhub.sh 
#!/bin/bash
credhub api https://192.168.0.11:8844   --skip-tls-validation
credhub login    --client-name=credhub-admin    --client-secret=xxxxxx


# test
credhub api
credhub find
```


# BOSH 접속
```
# Configure local alias
bosh alias-env b -e 192.168.0.11 --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca)

# Log in to the Director
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int ./creds.yml --path /admin_password`

# Query the Director for more info
bosh -e bosh-1 env

```
# bosh VM ssh접속
```
# bosh ssh key 생성
bosh int ./creds.yml --path /jumpbox_ssh/private_key > jumpbox_ssh.key

# jumpbox 계정으로 bosh 접속
ssh  -i  jumpbox_ssh.key  jumpbox@192.168.0.11

```

# BOSH Config Setting 
bosh create-env실행시 config정보가 필요하여  Opsmanager 정보를 참조하여 아래 작업 수행.
```
# setup cloud-config.yml 
ubuntu@opsmanager:~$ bosh -e m cloud-config  > cloud-config.yml

copy cloud-config.yml to jumpbox and edit.

ubuntu3@internal-jumpbox:~/bosh-1$ bosh -e b update-cloud-config ./cloud-config.yml

# cpi-config.yml
ubuntu@opsmanager:~$ bosh -e m cpi-config  >  cpi-config.yml

copy cpi-config.yml to jumpbox and edit.

ubuntu@internal-jumpbox:~/bosh-1$ bosh -e b update-cpi-config ./cpi-config.yml
```



# cf cli env

https://docs.cloudfoundry.org/cf-cli/install-go-cli.html#pkg-linux
```
wget https://cli.run.pivotal.io/stable?release=debian64&source=github
dpkg -i stable?release=debian64

```


# install docker engine env

- 외부에서 내려받은 다커 이미지를 내부 하버에 밀어넣기 위해 내부 점프박스에 다커 엔진이 필요하다. 
- 외부 점프박스에서 받아 설치해보고 내부 점프박스에 설치.

```
apt-get download libltdl7
apt download docker.io
dpkg -i libltdl7_2.4.6-0.1_amd64.deb 
dpkg -i docker.io_18.09.2-0ubuntu1~16.04.1_amd64.deb 
apt-get install -f
root@TLKPCFJB1:/home/ubuntu# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

```

# troubleshooting: wget download failure
```
wget https://cli.run.pivotal.io/stable?release=debian64&source=github

root@DojoJump:/etc/ssl# --2019-04-09 16:29:55-- https://cli.run.pivotal.io/stable?release=debian64
Resolving cli.run.pivotal.io (cli.run.pivotal.io)... 34.204.136.114, 34.194.131.211
Connecting to cli.run.pivotal.io (cli.run.pivotal.io)|34.204.136.114|:443... connected.
ERROR: cannot verify cli.run.pivotal.io's certificate, issued by emailAddress=admin@abc.com,CN=ABC,OU=ABC,O=ABC,L=ABC,ST=ABC,C=KR:
Self-signed certificate encountered.
To connect to cli.run.pivotal.io insecurely, use `--no-check-certificate'

```

how to import ABC corp certificate
```
1) export ABC corp cert(DER format)
2) copy to External jumpbox (ubuntu)
3) convert DER to PEM

openssl x509 -inform der -outform pem -in ABC.cer -out ABC.pem

4) cp ABC.pem /usr/local/share/ca-certificates/ABC.crt
Please note that the certificate filenames have to end in .crt, otherwise the update-ca-certificates script won't pick up on them.

5) root@DojoJump:/etc/ssl# update-ca-certificates
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.

wget https://cli.run.pivotal.io/stable?release=debian64&source=github
```

