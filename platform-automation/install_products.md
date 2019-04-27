
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




