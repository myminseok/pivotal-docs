
# How to setup concourse pipeline for installing/upgrading PAS tile
- http://docs.pivotal.io/platform-automation/v2.1/reference/pipeline.html#installing-ops-manager-and-tiles


## Config
- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-configuration-template
```
platform-automation-configuration-template
├── dev-1
│   ├── config
│   │   ├── auth-ldap.yml
│   │   ├── auth-saml.yml
│   │   └── auth.yml
│   ├── env
│   │   └── env.yml
│   ├── generated-config
│   ├── products
│   │   ├── cf.yml
│   │   ├── director.yml
│   │   ├── ops-manager.yml
│   │   └── pivotal-container-service.md
│   ├── products.yml
│   ├── state
│   │   └── state.yml
│   └── vars
│       ├── cf-vars.yml
│       ├── director-vars.yml
│       ├── global.yml
│       └── ops-manager-vars.yml
└── download-product-configs

```
### env.yml
- http://docs.pivotal.io/platform-automation/v2.1/configuration-management/configure-env.html

### cf.yml
```
1. run 'upload-and-stage-pas' job
2. <manually> configure PAS tile via opsmanager UI
  - to get domain self-signed certifiate:
   1. generate certs from opsmanager UI> PAS> networking
   2. copy certifiate to "domain.crt" file
   3. copy private key to "domain.key" file.
3. run 'generate-staged-config' in concourse pipeline:  
  - run with set SUBSTITUTE_CREDENTIALS_WITH_PLACEHOLDERS: true in pipeline.
  - will generate  generated-config/cf.yml in configuration git repository
4. copy generated-config/cf.yml to config/cf-<version>.yml
  - see <GIT>/<foundation>/config/cf.md 
5. set PLACEHOLDER value to concourse CREDHUB.
  - see <GIT>/<foundation>/config/cf.md 
  - use domain.crt and domain.key file in previous steps.
```




## pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template
```
platform-automation-pipelines-template git:(master)
├── fly-install-upgrade-opsman.sh
├── fly-install-upgrade-product.sh
├── fly-patch-opsman.sh
├── fly-patch-product.sh
├── install-upgrade-opsman.yml
├── install-upgrade-product.yml
├── patch-opsman.yml
├── patch-product.yml
├── tasks
├── vars-dev-1
│   └── common-params.yml
└── vars-pcfdemo
    └── common-params.yml
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
$ fly -t <fly-target> login -c https://your.concourse/ -b -k

$ ./fly-install-upgrade-opsman.sh <fly-target>  <foundation>
 - foundation: name of pcf foundation in platform-automation-config git.  
 - will create concourse pipeline named '<foundation>-opsman-install-upgrade'

$ ./fly-patch-opsman.sh <fly-target> <foundation>
 - foundation: name of pcf foundation in platform-automation-config git.  
 - will create concourse pipeline named '<foundation>-opsman-patch'

```

#### edit products.yml in git
edit version info \<platform-automation-configuration>/\<foundation>/products.yml from git and commit 
```
  products:
    cf:
      product-version: "2.6.3"
      pivnet-product-slug: elastic-runtime
      pivnet-file-glob: "*.pivotal"
      stemcell-iaas: vsphere
      s3-endpoint: http://my.s3.repo
      s3-region-name: "region"
      s3-bucket: "pivnet-products"
      s3-disable-ssl: "true"
      s3-access-key-id: ((s3_access_key_id))
      s3-secret-access-key: ((s3_secret_access_key))
      pivnet-api-token: ((pivnet_token))
```

#### prepare products
download product tile and stemcells from pivnet and upload to s3 as following:.
  - folder-sturcture format is as following and information comes from products.yml
  - pipeline matches a folder name of '[pivnet-product-slug, product-version]' in s3 bucket.
  - pipeline matches a file name 'pivnet-product-slug, product-version, pivnet-file-glob'.
  ```
  https://s3/pivnet-products/[elastic-runtime,2.6.3]/cf-2.6.3-build.21.pivotal
  https://s3/pivnet-products/[stemcells-ubuntu-xenial,250.56]/bosh-stemcell-250.56-vsphere-esxi-ubuntu-xenial-go_agent.tgz
  ```

#### run pipeline for install or upgrade product.
  1. download product tile and stemcells from pivnet and upload to s3 
  2. edit version info in products.yml from git and commit. 
  3. then the 'upload-and-stage-product-from-s3' job in the pipeline will automatically be triggered
  4. configure director tile manually.
  4. apply-product-change
  5. generate-staged-config. check generated-config git folder. copy to config \<platform-automation-configuration>/\<foundation>/\<product-name>.yml
  6. test 'configure-product'

####  patching product pipeline automation.
  1. download product tile and stemcells from pivnet and upload to s3 
  2. edit version info in products.yml from git and commit. 
  3. then the 'upload-and-stage-product-from-s3' job in the pipeline will automatically be triggered

#### reference
- PAS pipeline: https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/install_products.md
- product slug: https://github.com/brightzheng100/platform-automation-pipelines/blob/master/vars-dev/vars-products.yml

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






