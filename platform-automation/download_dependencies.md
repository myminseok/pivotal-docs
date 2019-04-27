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
#product-version-regex: ^2\.4\..*$
product-version-regex: ^2\.4\.5$
stemcell-iaas: vsphere

```


##  s3

```

|-- pivnet-products

`-- platform-automation
    |-- platform-automation-image-2.1.1-beta.1.tgz
    `-- platform-automation-tasks-2.1.1-beta.1.zip
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



