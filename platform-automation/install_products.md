
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


### how to prepare cf.yml before running 'configure-pas' job 
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
edit version info from \<platform-automation-configuration>/\<foundation>/products.yml in git and commit
```
  products:
    ops-mananager:
      product-version: "2.6.3"
      pivnet-product-slug: ops-manager-vsphere
      pivnet-file-glob: "*.ova"
      download-stemcell: "false"
      s3-endpoint: http://my.s3.repo
      s3-region-name: "region"
      s3-bucket: "pivnet-products"
      s3-disable-ssl: "true"
      s3-access-key-id: ((s3_access_key_id))
      s3-secret-access-key: ((s3_secret_access_key))
      pivnet-api-token: ((pivnet_token))
```
#### create s3 bucket
- for opsman backup: 'installation-\<foundation>'

#### prepare products
the pipeline download opsman ova from pivnet and upload to s3. folder sturcture should be compatible with 'om' cli which is used in 'paltform automation for PCF'. download product tile and stemcells from pivnet and upload to s3 as following:.
  - folder-sturcture format is as following and information comes from products.yml
  - pipeline matches a folder name of '[pivnet-product-slug, product-version]' in s3 bucket.
  - pipeline matches a file name 'pivnet-product-slug, product-version, pivnet-file-glob'.
  ```
  <s3-bucket>/[<products.ops-mananager>,<products.ops-manager.product-version>]/<products.ops-manager.pivnet-product-slug>-<products.ops-manager.product-version>-<products.ops-manager.pivnet-file-glob>
  
  ex) https://your.internal.s3/pivnet-products/[opsmanager,2.6.3]/ops-manager-vsphere-2.6.3-build.163.ova
  ```  
#### run pipeline for new opsman installation 
  1. create-new-opsman-vm
  2. configure-authentication
  3. generate-staged-config
   - it will extract director config and save to \<foundation>/generated-config/director.yml.
   - copy \<foundation>/generated-config/director.yml to \<foundation>/products/director.yml
   - edit \<foundation>/products/director.yml as following:
```
## add vcenter_password
iaas-configurations:
  - additional_cloud_properties: {}
  ...
    vcenter_username: 
    vcenter_password: 
  ...
## modify encryption
properties-configuration:
  director_configuration:
  ...
    #encryption: []
    encryption:
      keys: []
      providers: []
  ...
  #dns_configuration: []
  dns_configuration:
    excluded_recursors: []
    handlers: []
   ```
   - create \<foundation>/vars/director-vars.yml and edit secret key/values which maps to products/director.yml
  3. configure director tile manually.
  4. apply-director-change
  5. generate-staged-director-config > configure-director
 
#### run pipeline for minor upgrade opsman  
  1. upgrade-opsman-vm
  2. configure director tile manually.
  3. apply-director-change
  4. generate-staged-director-config > configure-director

#### run pipeline for patching opsman
  1. download opsman ova from pivnet and upload to s3 as following
  2. edit version info in products.yml from git and commit.
  3. then the 'replace-opsman-vm' job in the pipeline will automatically be triggered

### run pipeline for recovering opsman
  1. download opsman ova from pivnet and upload to s3 as following
  2. edit version info in products.yml from git and commit.
  3. create-new-opsman-vm
  4. import-installation
  5. apply-director-change
  then opsman will be recovered in a few minitues.




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






