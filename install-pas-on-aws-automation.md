
## check aws resource quota(limit)
extend resource limit of EC2:
https://docs.pivotal.io/pivotalcf/2-3/customizing/aws.html
```
vpc=> 5 free
vms=>
t2.micro: 50
c4.large: 20
m4.large: 20
r4.large: 20
```


## check azure resource quota(limit)
extend resource limit: https://docs.pivotal.io/pivotalcf/2-4/customizing/pcf_azure.html#raising-quota
```
We would like to raise our ARM (Azure Resource Manager) core limits.
Requested quantity of ARM Cores: 100
Requested region: japan central
VM Types to be used: F1s, F2s, F4s, DS11v2, DS12v2 VM count to 100 vms.
allocate 1 TB of standard storage.
```



## (for production env) prepare a wildcard domain for PAS foundation.
```
*.pcfdemo.net
*.apps.pcfdemo.net
*.system.pcfdemo.net
*.uaa.system.pcfdemo.net
*.login.system.pcfdemo.net
```

## sign up for network.pivotal.io 
get pivnet_token



## prepare storeage account on azure

storage is used by pcf-pipeline to store terraform.states file
```
az group create --name "my_terraform_gr" --location "japaneast"
az storage account create --name "my_terraform" --resource-group "my_terraform_gr" --location "japaneast" --sku "Standard_LRS"
az storage account keys list --account-name my_terraform --resource-group my_terraform_gr
az storage container create --name terraformstate --account-name my_terraform
```

## set variables to credhub

```
wget  https://raw.githubusercontent.com/pivotalservices/concourse-credhub/master/target-concourse-credhub.sh
bbl lbs
export CONCOURSE_URL=https://<concourse -lb-url>
source ./target-concourse-credhub.sh

$ crehub api
credhub set -t ssh -n /concourse/main/install-pcf-azure/git_private_key_ssh -p ~/.ssh/id_rsa
credhub set -t ssh -n /concourse/main/install-pcf-azure/pcf_ssh_key -p ~/.ssh/id_rsa -u ~/.ssh/id_rsa.pub


```


## edit pcf-install concourse pipeline

- for Seoul region( for two azs): https://github.com/myminseok/pcf-pipelines-minseok   
```
use AMI from opsmanager-aws in network.pivotal.io
```

- for Tokyo region: git clone https://github.com/pivotal-cf/pcf-pipelines  -> cd pcf-pipelines/install-pcf/aws
- for azure :https://github.com/pivotal-cf/pcf-pipelines -> cd pcf-pipelines/install-pcf/azure

~~~
git clone https://github.com/pivotal-cf/pcf-pipelines
cd ./pcf-pipelines
git checkout v0.23.12
git checkout -b pcf-2.4
cd ./install-pcf/azure

vi params.yml

# azure_vm_admin value should match with user ID used to create the certs pcf_ssh_key_pub.
# The user ID will appear towards the end of the public key.
azure_vm_admin: ubuntu


# Optional - if your git repo requires an SSH key.
git_private_key: ((git_private_key_ssh.private_key))

# SSH keys for Operations Manager director
pcf_ssh_key_pub: ((pcf_ssh_key.public_key))
pcf_ssh_key_priv: ((pcf_ssh_key.private_key))
  
~~~



## fly cli
~~~
fly client download(linux):
wget https://github.com/concourse/concourse/releases/download/v4.2.1/fly_linux_amd64
~~~

### fly login

~~~
fly -t sandbox login -c <concourse-url> -u <username> -p <password> -k 

cd pcf-pipelines/tree/master/install-pcf/aws
fly -t target sp -p install-pcf -c pipeline.yml -l ../../../params-aws.yml
~~~


