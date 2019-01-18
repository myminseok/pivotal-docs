

## create Jumpbox VM
create a single VM on target IaaS(Azure, AWS, GCP...) 
- 1~2 cpu, 2Gmem, 100Disk(persistent)
- OS: ubuntu 16.04 LTS
- vm name:  any name (but in azure env, try to use unique jumpbox name instead of 'jumpbox', because bbl will get confused with your jumpbox when bbl will create a bbl jumpbox)
- set port 22 for ssh access to the Jumpbox VM.

## update os dependency.
```
sudo su
apt update
apt-get install unzip

```

## installing all Utilities

https://github.com/cloudfoundry/bosh-bootloader

### bbl 
```
wget https://github.com/cloudfoundry/bosh-bootloader/releases/download/v6.10.3/bbl-v6.10.3_linux_x86-64
chmod +x bbl-v6.10.3_linux_x86-64
sudo mv bbl-v6.10.3_linux_x86-64 /usr/local/bin/bbl
bbl
```

### bosh-cli 

https://bosh.io/docs/cli-v2/
```
wget  https://github.com/cloudfoundry/bosh-cli/releases/download/v5.3.1/bosh-cli-5.3.1-linux-amd64
chmod +x bosh-cli-5.3.1-linux-amd64
sudo mv bosh-cli-5.3.1-linux-amd64 /usr/local/bin/bosh
bosh

```

### bosh-cli dependencies 

[bosh-cli dependencies](install_bosh_cli.md)

### terraform

https://www.terraform.io/downloads.html
version should be >= 0.11.0  
```
wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
unzip terraform_0.11.11_linux_amd64.zip
sudo mv terraform /usr/local/bin/terraform
terraform

```

### uaac 

install uaac after installing ruby v2.4+ and gem ([bosh-cli dependencies](install_bosh_cli.md)
```
# as root
# source /etc/profile.d/rvm.sh
gem install cf-uaac

uaac

```

## mount disk
```
fdisk -l
mkfs.ext4 /dev/sdc
mkdir /store
mount /dev/sdc /store
```

=====================================================================

Following is optional settings 

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
