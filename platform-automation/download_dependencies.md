## Ref
- http://docs.pivotal.io/platform-automation/v2.1/index.html



## Config

- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html#download-product-config

- sample: https://github.com/myminseok/platform-automation-configuration-template


```
platform-automation-conf
└── dev-1
    ├── config
    ├── download-product-configs
    │   ├── healthwatch.yml
    │   ├── opsman.yml
    │   └── pas.yml
    ├── env
    │   └── env.yml
    └── vars

```
opsman.yml
```
---
pivnet-api-token: ((pivnet_token))
pivnet-file-glob: "*vsphere*.ova"
pivnet-product-slug: ops-manager
product-version-regex: ^2\.4\..*$

```

pas.yml
```
---
pivnet-api-token: ((pivnet_token))
pivnet-file-glob: "cf-*.pivotal"
pivnet-product-slug: elastic-runtime
product-version-regex: ^2\.4\..*$
stemcell-iaas: vsphere

```


##  s3

```

|-- pivnet-products

`-- platform-automation
    |-- platform-automation-image-2.1.1-beta.1.tgz
    `-- platform-automation-tasks-2.1.1-beta.1.zip
```


###  Set Pipeline secrets to concourse credhub  per each foundation
login to credhub
```
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat login-credhub.sh
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://credhub.pcfdemo.net:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)

```
set  per each foundation, `dev` for this case 
```
## /concourse/dev
credhub set -t value -n /concourse/dev/s3_access_key_id -v <S3_ACCESS_KEY>
credhub set -t value -n /concourse/dev/s3_secret_access_key -v "<S3_SECRET>"
credhub set -t value -n /concourse/dev/pivnet_token -v <YOUR_PIVNET_TOKEN>

credhub set -t value -n /concourse/dev/git_user_email -v <GIT_USER_EMAIL>
credhub set -t value -n /concourse/dev/git_user_username -v <GIT_USER_NAME>

credhub set -t user -n /concourse/dev/vcenter_user -z <user> -w <password>

# register ssh key for git. ex) ~/.ssh/id_rsa
credhub set -t rsa  -n /concourse/dev/git_private_key  -p ~/.ssh/id_rsa 
 
cd concourse-bosh-deployment/cluster
# bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub set -t certificate -n /concourse/dev/credhub_ca_cert -c ./credhub-ca.ca

# grep concourse_to_credhub ./concourse-creds.yml
credhub set -t user -n /concourse/dev/credhub_client -z concourse_client -w <concourse_to_credhub>

credhub set -t user  -n /concourse/dev/opsman_admin -z admin -w <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev/decryption-passphrase -v <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev/opsman_target -v https://opsman_url_or_IP

```


## Pipeline
- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/pipeline.html#retrieving-external-dependencies

- sample: https://github.com/myminseok/platform-automation-pipelines-template



```
fly -t demo sp -p download-product -c download-product.yml -l ./download-product-params.yml
```


##  S3 

```
|-- pivnet-products
|   |-- cf-2.4.5-build.25.pivotal
|   |-- healthwatch-stemcell
|   |   `-- bosh-stemcell-97.71-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |-- pas-stemcell
|   |   |-- bosh-stemcell-170.45-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |   `-- bosh-stemcell-170.48-vsphere-esxi-ubuntu-xenial-go_agent.tgz
|   |-- pcf-vsphere-2.4-build.171.ova
|   `-- p-healthwatch-1.4.5-build.41.pivotal
`-- platform-automation
    |-- platform-automation-image-2.1.1-beta.1.tgz
    `-- platform-automation-tasks-2.1.1-beta.1.zip
```



