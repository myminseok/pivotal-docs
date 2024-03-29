#  Jumpbox for air-gapped envirionment 
there are two jumpboxes(internal, external)
- other options: https://github.com/cloudfoundry/jumpbox-deployment

## create EXTERNAL jumpbox 


### VM spec
- Ubuntu-server 16.04 LTS, 20.04 , 64 bit  http://releases.ubuntu.com/xenial/
- Ubuntu-server 20.04 LTS, 20.04 , 64 bit  http://releases.ubuntu.com/
- 2cpu, 4gbmem, os disk 3gb, persistent disk 500GB - 1TB


## volume mount
https://github.com/myminseok/pivotal-docs/blob/master/offline/mount.md

=====================================================================

Following is optional settings 

###  ifconfig

```
sudo apt install net-tools
```
*  generating ssh -key
* for windows, use PuttyGen: https://www.ssh.com/ssh/putty/windows/puttygen
```
$ ssh-keygen 
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/labsproject/.ssh/id_rsa): 
Created directory '/Users/labsproject/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /Users/labsproject/.ssh/id_rsa.
Your public key has been saved in /Users/labsproject/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:xxxxx M labsproject@Pivotals-iMac-2.local
The key's randomart image is:
+---[RSA 2048]----+
|      .o..       |
|       oo        |
|      . ..       |
|     .   o.      |
|    . ..S  .     |
|     o E=.  . o. |
|      .+ o.oo+..=|
|        *o==+=.=o|
|       .=X=*@OB. |
+----[SHA256]-----+
$ ls ~/.ssh/
id_rsa		id_rsa.pub


```

### CLIs
```
git
pivnet: https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1
om: https://github.com/pivotal-cf/om/releases/download/7.2.0/om-linux-7.2.0
cf
bosh
```

### (external jumpbox) download files

#  bosh cli dependency
https://bosh.io/docs/cli-v2-install/#ubuntu

```
mkdir  /home/ubuntu/bosh-download && cd /home/ubuntu/bosh-download

# download bosh dependency binaries
ubuntu@external-jumpbox:~/bosh-download$ sudo apt-get update

sudo apt-get download -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3

ubuntu@external-jumpbox:~/bosh-download$  apt-get download libcurl3

```
https://github.com/cloudfoundry/bosh-cli/releases

```
wget https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.1/bosh-cli-6.4.1-linux-amd64

```


# cf cli
```
wget https://docs.cloudfoundry.org/cf-cli/install-go-cli.html#pkg-linux
wget -O cf.deb https://cli.run.pivotal.io/stable?release=debian64&source=github
```

## Install git cli (jumpbox)
https://git-scm.com/book/en/v2/Getting-Started-Installing-Git



### (external jumpbox) install depencencies test

```
sudo su
cd /home/ubuntu/bosh-download
ubuntu@external-jumpbox:~/bosh-download$  dpkg -i *.deb
ubuntu@external-jumpbox:~/bosh-download$  apt-get install -f
ubuntu@external-jumpbox:~/bosh-download$  apt list --installed
```


### (external jumpbox) Download bosh releases
```
mkdir /home/ubuntu/bosh-1 && cd /home/ubuntu/bosh-1

ubuntu@external-jumpbox:~/bosh-1$  sudo apt-get install git-core
ubuntu@external-jumpbox:~/bosh-1$ git clone https://github.com/cloudfoundry/bosh-deployment

# download release for ./bosh-deployment/bosh.yml 
ubuntu@external-jumpbox:~/bosh-1$ grep -r "https://.*tgz" ./bosh-deployment/bosh.yml
  url: https://s3.amazonaws.com/bosh-compiled-release-tarballs/bosh-270.4.0-ubuntu-xenial-456.3-20190731-215637-531978373-20190731215643.tgz
  url: https://s3.amazonaws.com/bosh-compiled-release-tarballs/bpm-1.1.1-ubuntu-xenial-456.3-20190731-215300-188195798-20190731215308.tgz
ubuntu@external-jumpbox:~/bosh-1$ grep -r "https://.*tgz" ./bosh-deployment/bosh.yml | awk '{print $2}' | xargs wget

# download release for ./bosh-deployment/uaa.yml 
ubuntu@external-jumpbox:~/bosh-1$ grep -r "https://.*tgz" ./bosh-deployment/uaa.yml
    url: https://s3.amazonaws.com/bosh-compiled-release-tarballs/uaa-73.7.0-ubuntu-xenial-456.3-20190731-220205-231093525-20190731220215.tgz
ubuntu@external-jumpbox:~/bosh-1$ grep -r "https://.*tgz" ./bosh-deployment/bosh.yml | awk '{print $2}' | xargs wget
    
# download release for ./bosh-deployment/vsphere/cpi.yml
ubuntu@external-jumpbox:~/bosh-1$ grep -r "https://.*tgz" ./bosh-deployment/vsphere/cpi.yml
    url: https://s3.amazonaws.com/bosh-core-stemcells/456.3/bosh-stemcell-456.3-vsphere-esxi-ubuntu-xenial-go_agent.tgz    
ubuntu@external-jumpbox:~/bosh-1$ grep -r "https://.*tgz" ./bosh-deployment/vsphere/cpi.yml  | awk '{print $2}' | xargs wget

```

### (external jumpbox) edit bosh-deployment 
```
cd /home/ubuntu/bosh-1

ubuntu@external-jumpbox:~/bosh-1$ vi bosh-deployment/bosh.yml
url: https://s3.amazonaws.com/bosh-compiled-release-tarballs
=> 
url: file:///home/ubuntu/bosh-1

ubuntu@external-jumpbox:~/bosh-1$ vi bosh-deployment/uaa.yml
url: https://s3.amazonaws.com/bosh-compiled-release-tarballs
=> 
url: file:///home/ubuntu/bosh-1

ubuntu@external-jumpbox:~/bosh-1$ vi bosh-deployment/vsphere/cpi.yml
url: https://bosh.io/d/stemcells
-> 
url: file:///home/ubuntu/bosh-1

```

### (external jumpbox) install bosh cli
```
cd /home/ubuntu/bosh-1
ubuntu@external-jumpbox:~/bosh-1$ wget https://github.com/cloudfoundry/bosh-cli/releases/download/v5.4.0/bosh-cli-5.4.0-linux-amd64
ubuntu@external-jumpbox:~/bosh-1$ chmod +x bosh-cli-5.4.0-linux-amd64
ubuntu@external-jumpbox:~/bosh-1$ sudo cp bosh-cli-5.4.0-linux-amd64 /usr/local/bin/bosh
ubuntu@external-jumpbox:~/bosh-1$ bosh -v
```

### (external jumpbox) run `bosh create-env` 
to download depencency to /home/ubuntu/.bosh
```
ubuntu@external-jumpbox:~/bosh-1$ vi deploy.sh 

bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -o bosh-deployment/jumpbox-user.yml \
    -o bosh-deployment/uaa.yml \
    -o bosh-deployment/credhub.yml \
    -o bosh-deployment/misc/config-server.yml \
    -o bosh-deployment/misc/dns.yml \
    -v director_name=bosh-1 \
    -v internal_cidr=192.168.0.0/24 \
    -v internal_gw=192.168.0.1 \
    -v internal_ip=192.168.0.10 \
    -v internal_dns="[8.8.8.8]" \
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

ubuntu@external-jumpbox:~/bosh-1$ ./deploy.sh
...

```
## (external jumpbox) copy downloaded files to internal jumpbox
```
cd /home/ubuntu

tar zcf bosh-download.tar.gz ./bosh-download
scp bosh-download.tar.gz ubuntu@<INTERNAL-JUMPBOX>:/home/ubuntu/bosh-download.tar.gz

cd /home/ubuntu
tar zcf bosh-1.tar.gz ./bosh-1
scp bosh-1.tar.gz ubuntu@<INTERNAL-JUMPBOX>:/home/ubuntu/bosh-1.tar.gz

cd /home/ubuntu
tar zcf bosh-cache.tar.gz .bosh
scp bosh-cache.tar.gz ubuntu@<INTERNAL-JUMPBOX>:/home/ubuntu/bosh-cache.tar.gz

```


## create INTERNAL jumpbox 

### VM spec
- Ubuntu 16.04 LTS, 64 bit  http://releases.ubuntu.com/xenial/
- 2cpu, 4gbmem, os disk 10gb, persistent disk 100gb ~ 500gb

### NO internet
##### (internal jumpbox, NO internet) install depencencies
https://bosh.io/docs/cli-v2-install/
```
cd /home/ubuntu
tar xf bosh-download.tar.gz
tar xf bosh-1.tar.gz
tar xf bosh-cache.tar.gz

sudo su
cd /home/ubuntu/bosh-download
ubuntu@internal-jumpbox:~/bosh-download$  dpkg -i *.deb
ubuntu@internal-jumpbox:~/bosh-download$  apt-get install -f
ubuntu@internal-jumpbox:~/bosh-download$  apt list --installed

```

##### (internal jumpbox, NO internet) install bosh cli
```
cd /home/ubuntu/bosh-1
ubuntu@internal-jumpbox:~/bosh-1$ chmod +x bosh-cli-5.4.0-linux-amd64
ubuntu@internal-jumpbox:~/bosh-1$ sudo cp bosh-cli-5.4.0-linux-amd64 /usr/local/bin/bosh
ubuntu@internal-jumpbox:~/bosh-1$ bosh -v
```

### (internal jumpbox, WITH internet) install bosh cli 

https://bosh.io/docs/cli-v2-install/#ubuntu

```
ubuntu@internal-jumpbox: $ sudo apt-get update

ubuntu@internal-jumpbox: $ sudo apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3

ubuntu@internal-jumpbox: $ sudo  apt-get download libcurl3  -y

```
https://github.com/cloudfoundry/bosh-cli/releases

```
wget https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.1/bosh-cli-6.4.1-linux-amd64
chmod +x bosh-cli-6.4.1-linux-amd64
sudo cp bosh-cli-6.4.1-linux-amd64 /usr/local/bin/bosh
bosh -v


```




### (internal jumpbox) deploy bosh director vm 
https://bosh.io/docs/init-vsphere/
```
ubuntu@external-jumpbox:~/bosh-1$ vi deploy.sh 

bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -o bosh-deployment/jumpbox-user.yml \
    -o bosh-deployment/uaa.yml \
    -o bosh-deployment/credhub.yml \
    -o bosh-deployment/misc/config-server.yml \
    -o bosh-deployment/misc/dns.yml \
    -v director_name=bosh-1 \
    -v internal_cidr=192.168.0.0/24 \
    -v internal_gw=192.168.0.1 \
    -v internal_ip=192.168.0.10 \
    -v internal_dns="[8.8.8.8]" \
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

ubuntu@internal-jumpbox:~/bosh-1$ ./deploy.sh
...

```


### login to BOSH director
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
https://bosh.io/docs/cloud-config/
https://bosh.io/docs/cpi-config/
```
# setup cloud-config.yml 


ubuntu@opsmanager:~$ bosh -e m cloud-config  > cloud-config.yml

copy cloud-config.yml to jumpbox and edit.

ubuntu@internal-jumpbox:~/bosh-1$ bosh -e b update-cloud-config ./cloud-config.yml

# cpi-config.yml


ubuntu@opsmanager:~$ bosh -e m cpi-config  >  cpi-config.yml

copy cpi-config.yml to jumpbox and edit.

ubuntu@internal-jumpbox:~/bosh-1$ bosh -e b update-cpi-config ./cpi-config.yml
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

# cf cli env

https://docs.cloudfoundry.org/cf-cli/install-go-cli.html#pkg-linux
```
wget https://cli.run.pivotal.io/stable?release=debian64&source=github
dpkg -i stable?release=debian64

```
# docker
https://github.com/myminseok/pivotal-docs/blob/master/offline/docker.md


# harbor
https://github.com/myminseok/pivotal-docs/blob/master/offline/harbor.md

## no password
```
vi /etc/sudoers


# User privilege specification
root    ALL=(ALL:ALL) ALL
### ubuntu  ALL=(ALL) NOPASSWD: ALL #<---group sudo 다음에 작성해야함.

# Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL

# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL

ubuntu  ALL=(ALL) NOPASSWD: ALL   #<======
```
