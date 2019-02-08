
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
## prepare contron-plane(concourse)
- [bbl-aws](bbl.md)
- [bbl-azure](bbl-azure.md)
- [concourse-with-credhub](concourse-with-credhub.md)


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

- for Seoul region( for two azs): https://github.com/myminseok/pcf-pipelines-minseok   
```
use AMI from opsmanager-aws in network.pivotal.io
```

- for Tokyo region: git clone https://github.com/pivotal-cf/pcf-pipelines  -> cd pcf-pipelines/install-pcf/aws

~~~
git clone https://github.com/pivotal-cf/pcf-pipelines
cd ./pcf-pipelines
git checkout v0.23.12
git checkout -b pcf-2.4
cd ./install-pcf/aws

vi params.yml

# Prefix to use for Terraform-managed infrastructure, e.g. 'pcf-terraform'
# Must be globally unique.
# check following blobs are available using curl.

azure_terraform_prefix: minseokterr


# Optional - if your git repo requires an SSH key.
git_private_key: ((git_private_key_ssh.private_key))

# SSH keys for Operations Manager director
pcf_ssh_key_pub: ((pcf_ssh_key.public_key))
pcf_ssh_key_priv: ((pcf_ssh_key.private_key))


# Disable HTTP on gorouters (true|false)
disable_http_proxy: true


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


