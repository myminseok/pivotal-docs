
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
*.<your domain>
*.apps.<your domain>
*.system.<your domain>
*.uaa.system.<your domain>
*.login.system.<your domain>
```

## sign up for network.pivotal.io 
get pivnet_token


## prepare storeage account on azure

storage is used by pcf-pipeline to store terraform.states file <br>

```
storage account name is unigue name, check if it is available.
$ curl https://<YOUR-STORAGE-ACCOUNT-NAME>.blob.core.windows.net/
curl: (6) Could not resolve host: https://<YOUR-STORAGE-ACCOUNT-NAME>.blob.core.windows.net/


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
$ credhub find

## if you don't have ssh key for github.com, run ssh-keygen and register ~/.ssh/id_rsa.pub to github.com
$ credhub set -t ssh -n /concourse/main/install-pcf/git_private_key_ssh -p ~/.ssh/id_rsa
$ credhub set -t ssh -n /concourse/main/install-pcf/pcf_ssh_key -p ~/.ssh/id_rsa -u ~/.ssh/id_rsa.pub


```


## edit pcf-install concourse pipeline

- for azure :https://github.com/pivotal-cf/pcf-pipelines -> cd pcf-pipelines/install-pcf/azure

~~~
git clone https://github.com/pivotal-cf/pcf-pipelines
cd ./pcf-pipelines
git checkout v0.23.12
git checkout -b pcf-2.4
cd ./install-pcf/azure

vi params.yml

# Prefix to use for Terraform-managed infrastructure, e.g. 'pcf-terraform'
# Must be globally unique.
# check following blobs are available using curl.
# pipeline will remove special character and use initial 10 characters
# azure_terraform_prefix+ "root"
# azure_terraform_prefix+ "infra"
# azure_terraform_prefix+ azure_storage_account_name
# azure_terraform_prefix+ "vms1"
# azure_terraform_prefix+ "vms2"
# azure_terraform_prefix+ "vms3"
$ curl https://<YOUR-STORAGE-ACCOUNT-NAME>.blob.core.windows.net/

azure_terraform_prefix: minseokterr


# azure_vm_admin value should match with user ID used to create the certs "pcf_ssh_key_pub"
# The user ID will appear towards the end of the public key.
azure_vm_admin: ubuntu


# Optional - if your git repo requires an SSH key.
git_private_key: ((git_private_key_ssh.private_key))

# SSH keys for Operations Manager director
pcf_ssh_key_pub: ((pcf_ssh_key.public_key))
pcf_ssh_key_priv: ((pcf_ssh_key.private_key))



# Storage account and container that will be used for your terraform state
azure_storage_container_name:  <-- $ az storage container create --name terraformstate 
terraform_azure_storage_access_key:   <-- key from $ az storage account keys list --account-name <YOUR-STORAGE-ACCOUNT-NAME>
terraform_azure_storage_account_name: <-- $ az storage account create --name "my_terraform"
  
  
# Disable HTTP on gorouters (true|false)
disable_http_proxy: true

# If enabled HAProxy will forward all requests to the router over TLS (enable|disable)
haproxy_forward_tls: false



# Support for the X-Forwarded-Client-Cert header. Possible values: (load_balancer|ha_proxy|router)
routing_tls_termination: router

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

## pipeline name should be match with the param name in the credhub. ex) /concourse/main/install-pcf/*
fly -t target sp -p install-pcf -c pipeline.yml -l ../../../params-aws.yml


# run 
1. bootstrap-terraform-state
2. create-infrastructure
3. setup your DNS for your pcf domain.  dig opsman.<your pcf domain>
4. run config-opsman-auth
5.
~~~


