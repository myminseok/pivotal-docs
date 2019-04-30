
# Install PAS

## Ref
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

### cf.yml
how to make cf.yml
```
1) stage PAS on opsmanager.
2) configure the PAS via opsmanager UI

3) 'staged-pas-config' in concourse pipeline:  
  - set SUBSTITUTE_CREDENTIALS_WITH_PLACEHOLDERS: true
4) run 'staged-pas-config' in concourse pipeline( 'om staged-config') 
5) see generated-config/cf.yml in configuration git project 
6) you need to replace PLACEHOLDERS:
  - put your password
  - replace with "" for empty value
  - for certificate, put as following, be careful of indentation:

  .properties.networking_poe_ssl_certs:
    value:
    - certificate:
        cert_pem: |
          -----BEGIN CERTIFICATE -----
          MIIEowIBAAKCAQEAwoRC94Doakj34YEVX7E8rl83JhKsQ62nYnK4bSP0Y0FbS51Q
          bvzVaqmfTLtwUCyRPresy4Aaj6IHKA6FTvjVrYyxHq6d5ExP0RxJwG10jxI29VKT
          ...

        private_key_pem: |
          -----BEGIN RSA PRIVATE KEY-----
          MIIEowIBAAKCAQEAwoRC94Doakj34YEVX7E8rl83JhKsQ62nYnK4bSP0Y0FbS51Q
          bvzVaqmfTLtwUCyRPresy4Aaj6IHKA6FTvjVrYyxHq6d5ExP0RxJwG10jxI29VKT
      name: Certificate 1

```


or use tile-config-generator to get cf.yml template(template only)
- https://github.com/pivotalservices/tile-config-generator





## pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template

### install-products-params.yml
```

foundation: dev-1

s3:
  endpoint: https:///s3.pcfdemo.net
  access_key_id: ((s3_access_key_id))
  secret_access_key: ((s3_secret_access_key))
  region_name: ""
  buckets:
    platform_automation: platform-automation
    foundation: dev-1
    pivnet_products: pivnet-products
    installation: installation

git:
  platform_automation_tasks:
    uri: pivotal@git.pcfdemo.net/platform/platform_automation_tasks.git
  configuration:
    uri: pivotal@git.pcfdemo.net:platform/platform-conf.git
  variable:
    uri: pivotal@git.pcfdemo.net:platform/platform-conf.git
  user: 
    email: ((git_user.email))
    username: ((git_user.username))
  private_key: ((git_private_key.private_key))

credhub:
  server: https://concourse.pcfdemo.net:8844
  ca_cert: ((credhub_ca_cert.certificate))
  client: ((credhub_client.username))
  secret: ((credhub_client.password))
  interpolate_folders: dev-1/config dev-1/env


pivnet: 
  token: ((pivnet_token))

#opsman_image_s3_versioned_regexp:  "*vsphere*.ova"
opsman_image_s3_versioned_regexp:  pcf-vsphere-(.*).ova

```



###  register secret to concourse credhub.
```

credhub set -t value -n /concourse/main/s3_access_key_id -v <S3_ACCESS_KEY>
credhub set -t value -n /concourse/main/s3_secret_access_key -v "<S3_SECRET>"
credhub set -t value -n /concourse/main/pivnet_token -v <YOUR_PIVNET_TOKEN>


credhub set -t value -n /concourse/main/git_user_email -v <GIT_USER_EMAIL>
credhub set -t value -n /concourse/main/git_user_username -v <GIT_USER_NAME>

# register ssh key for git. ex) ~/.ssh/id_rsa
credhub set -t rsa  -n /concourse/main/git_private_key  -p ~/.ssh/id_rsa 
 
cd concourse-bosh-deployment/cluster
bosh int ./concourse-creds.yml --path /atc_tls/certificate > atc_tls.cert
credhub set -t certificate -n /concourse/main/credhub_ca_cert -c ./atc_tls.cert

grep concourse_to_credhub ./concourse-creds.yml
credhub set -t user -n /concourse/main/credhub_client -z concourse_to_credhub -w <concourse_to_credhub>

credhub set -t user  -n /concourse/dev-1/opsman_admin -z admin -w <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/decryption-passphrase -v <YOUR_PASSWORD>
credhub set -t value -n /concourse/dev-1/opsman_target -v https://opsman_url_or_IP


```

## run pipeline

```
fly -t demo sp -p install-products -c install-products.yml -l ./install-products-params.yml

```


