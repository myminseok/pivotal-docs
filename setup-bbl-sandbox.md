

## create Jumpbox VM
create a single VM on target IaaS(Azure, AWS, GCP...) 
- 1~2 cpu, 2Gmem, 100Disk(persistent)
- OS: ubuntu 16.04 LTS
- vm name:  any name (but in azure env, try to use unique jumpbox name instead of 'jumpbox', because bbl will get confused with your jumpbox when bbl will create a bbl jumpbox)
- set port 22 for ssh access to the Jumpbox VM. 
- (!!! best practice: limit ssh  access to limited CIDR by setting source IP in security group)
- sshing vm troubleshooting https://aws.amazon.com/premiumsupport/knowledge-center/ec2-linux-ssh-troubleshooting/
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

# activate the rvm env.
source /etc/profile.d/rvm.sh

gem install cf-uaac

uaac

```

