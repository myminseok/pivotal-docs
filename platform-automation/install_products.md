
# How to setup concourse pipeline for installing/upgrading PAS tile
- http://docs.pivotal.io/platform-automation/v2.1/reference/pipeline.html#installing-ops-manager-and-tiles


## Config
- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-configuration-template
```
platform-automation-configuration-template
└── dev-1
    ├── config
    │   ├── cf.yml
    │   ├── auth.yml    
    │   └── opsman-2.4.yml
    ├── download-product-configs
    ├── env
    │   └── env.yml             
    ├── generated-config
    ├── state
    └── vars

```
### env.yml
- http://docs.pivotal.io/platform-automation/v2.1/configuration-management/configure-env.html



## pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template
```

├── common-params.yml
├── dev-1
│   ├── download-product-params.yml
│   └── env-params.yml
├── pas.sh
├── pas.yml
├── tasks
│   ├── apply-product-changes.yml
│   ├── staged-director-config.yml
```


### common-params.yml
```
s3:
  endpoint: http://10.10.10.199:9000
  access_key_id: ((s3_access_key_id))
  secret_access_key: ((s3_secret_access_key))
  region_name: ""
  buckets:
    platform_automation: platform-automation
    pivnet_products: pivnet-products
    installation: installation
    bbr-backup: bbr-pcfdemo

git:
  platform_pipelines:
   # uri: ssh://pivotal@10.10.10.199/platform/platform-pipelines.git
   uri: git@github.com:myminseok/platform-automation-pipelines-template.git
  platform_automation_tasks:
    uri: ssh://pivotal@10.10.10.199/platform/platform_automation_tasks.git
  configuration:
    uri: pivotal@10.10.10.199:platform/platform-conf.git
  variable:
    uri: pivotal@10.10.10.199:platform/platform-conf.git
  user: 
    email: user@pivotal.io
    #username: ((git_user.username))
    username: "Platform Automation Bot"
  private_key: ((git_private_key.private_key))

credhub:
  server: https://concourse.pcfdemo.net:8844
  ca_cert: ((credhub_ca_cert.certificate))
  client: ((credhub_client.username))
  secret: ((credhub_client.password))

vcenter:
  datacenter: datacenter
  insecure: 1
  url: 10.10.10.10
  username: ((vcenter_user.username))
  password: ((vcenter_user.password))

pivnet: 
  token: ((pivnet_token))
```

### dev-1/env-params.yml
```

foundation: dev-1

#opsman_image_versioned_regexp:  .*-vsphere-(2\.4-.*).ova
opsman_image_versioned_regexp:  ops-manager-vsphere-(2\.5\.5.*).ova

#pas_product_versioned_regexp: cf-(.*).pivotal
pas_product_versioned_regexp: cf-(2\.5).pivotal
pas_stemcell_versioned_regexp: pas-stemcell/bosh-stemcell-(.*)-vsphere.*\.tgz

pks_product_versioned_regexp: pivotal-container-service-(1\.4\..*).pivotal
pks_stemcell_versioned_regexp: pks-stemcell/bosh-stemcell-(.*)-vsphere.*\.tgz

pas_config_file: cf-2.5.yml
pks_config_file: pivotal-container-service-1.4.yml
```

###  register secrets to concourse credhub.
```
## /concourse/main
credhub set -t value -n /concourse/main/s3_access_key_id -v <S3_ACCESS_KEY>
credhub set -t value -n /concourse/main/s3_secret_access_key -v "<S3_SECRET>"
credhub set -t value -n /concourse/main/pivnet_token -v <YOUR_PIVNET_TOKEN>

credhub set -t value -n /concourse/main/git_user_email -v <GIT_USER_EMAIL>
credhub set -t value -n /concourse/main/git_user_username -v <GIT_USER_NAME>

credhub set -t user -n /concourse/main/vcenter_user -z <user> -w <password>

# register ssh key for git. ex) ~/.ssh/id_rsa
credhub set -t rsa  -n /concourse/main/git_private_key  -p ~/.ssh/id_rsa 
 
cd concourse-bosh-deployment/cluster
bosh int ./concourse-creds.yml --path /atc_tls/certificate > atc_tls.cert
credhub set -t certificate -n /concourse/main/credhub_ca_cert -c ./atc_tls.cert

grep concourse_to_credhub ./concourse-creds.yml
credhub set -t user -n /concourse/main/credhub_client -z concourse_to_credhub -w <concourse_to_credhub>


## /concourse/dev-1
credhub set -t user  -n /concourse/dev-1/opsman_admin -z admin -w <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/decryption-passphrase -v <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/opsman_target -v https://opsman_url_or_IP


```

## run pipeline

```
fly -t demo login -c https://<concourse> -u your-user -p xxx -k
fly -t demo sp -p pas-install -c pas.yml -l ./common-params.yml -l ./dev-1/env-params.yml

or 

./pas.sh <foundation>
```


## how to prepare cf.yml before running 'configure-pas' job 
```
1. run 'upload-and-stage-pas' job
2. <manually> configure PAS tile via opsmanager UI
  - to get domain self-signed certifiate:
   1. generate certs from opsmanager UI> PAS> networking
   2. copy certifiate to "domain.crt" file
   3. copy private key to "domain.key" file.
3. run 'extract-staged-pas-config' in concourse pipeline:  
  - run with set SUBSTITUTE_CREDENTIALS_WITH_PLACEHOLDERS: true in pipeline.
  - will generate  generated-config/cf-<foundation>.yml in configuration git repository
4. create config/cf-<version>.yml 
  - copy generated-config/cf-<foundation>.yml to config/cf-<version>.yml
  - see <GIT>/<foundation>/config/cf.md 
5. set PLACEHOLDER value to concourse CREDHUB.
  - see <GIT>/<foundation>/config/cf.md 
  - use domain.crt and domain.key file in previous steps.
```



## how to extract secret value from PAS
```
root@d50b90c0-7288-4194-5611-4799d7ad34ea:/tmp/build/4a564f8b# om --env ./env/dkpcf/env/env.yml credential-references -p cf | grep poe
| .properties.networking_poe_ssl_certs[0].certificate


root@d50b90c0-7288-4194-5611-4799d7ad34ea:/tmp/build/4a564f8b# om --env ./env/dkpcf/env/env.yml credentials -p cf -c .properties.networking_poe_ssl_certs[0].certificate
+------------------------------------------------------------------+------------------------------------------------------------------+
| cert_pem | private_key_pem |
+------------------------------------------------------------------+------------------------------------------------------------------+
| | -----BEGIN RSA PRIVATE KEY-----
| MIIEpAIBAAKCAQEA1Xu8fbAMsJpjIQYRQ1Kv6L2R1ZpB1/i74tIj3SHtKs76Yss1
...
|AZokZDWW5Lb3eKoAInGbQ9tsfrJeADL0jSINt/2bIF1QA7g==l+wctiD
| -----END RSA PRIVATE KEY-----
```


or use tile-config-generator to get cf.yml template(template only)
- https://github.com/pivotalservices/tile-config-generator






