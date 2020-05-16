
## Get concourse pipeline and configs template

in jumpbox,as ubuntu user
``` bash
mkdir platform-automation-workspace
cd platform-automation-workspace

git clone https://github.com/myminseok/platform-automation-pipelines-template   platform-automation-pipelines
git clone https://github.com/myminseok/platform-automation-configuration-template   platform-automation-configuration

mv platform-automation-configuration-template platform-automation-configuration
mv platform-automation-pipelines-template platform-automation-pipelines

```

## folder structure
platform-automation-configuration has configs per each foundation
[sample](https://github.com/myminseok/platform-automation-configuration-template)
```
platform-automation-workspace/platform-automation-configuration
├── awstest
│   ├── download-products
│   │   ├── healthwatch.yml
│   │   ├── opsman.yml
│   │   ├── pks.yml
│   │   └── tas.yml
│   ├── opsman
│   │   ├── auth.yml
│   │   ├── director.yml
│   │   ├── env.yml
│   │   └── opsman.yml
│   ├── pipeline-vars
│   │   ├── params.yml
│   │   ├── prepare-credhub-secrets-from-terraform-state.sh
│   │   ├── set-credhub-from-terraform.sh
│   │   ├── set-credhub.sh
│   │   └── terraform.tfvars
│   ├── products
│   │   ├── tas.yml
│   │   └── versions.yml
│   ├── state
│   │   └── state.yml
│   └── vars
│       ├── director.yml
│       ├── opsman.yml
│       └── tas.yml
├── dev
│   ├── download-products
│   │   ├── healthwatch.yml
│   │   ├── opsman.yml
│   │   ├── pks.yml
│   │   └── tas.yml
│   ├── opsman
│   │   ├── auth.yml
│   │   ├── director.yml
│   │   ├── env.yml
│   │   └── opsman.yml
│   ├── pipeline-vars
│   │   ├── params.yml
│   │   ├── prepare-credhub-secrets-from-terraform-state.sh
│   │   ├── set-credhub-from-terraform.sh
│   │   ├── set-credhub.sh
│   │   └── terraform.tfvars
│   ├── products
│   │   ├── tas.yml
│   │   └── versions.yml
│   ├── state
│   │   └── state.yml
│   └── vars
│       ├── director.yml
│       ├── opsman.yml
│       └── tas.yml
```

## pipeline 
[sample](https://github.com/myminseok/platform-automation-pipelines-template)
```
platform-automation-workspace/platform-automation-pipelines
├── install-upgrade-all-aws.sh
├── install-upgrade-all-aws.yml
├── tasks
│   ├── bbr-backup-director.sh
│   ├── bbr-backup-director.yml
│   ├── bbr-backup-pas.sh
│   ├── bbr-backup-pas.yml
│   ├── check_state_file.sh
│   ├── download-only-product.sh
│   ├── download-only-product.yml
│   ├── download-product-s3.sh
│   ├── download-product-s3.yml
│   ├── exists_file_s3.sh
│   ├── exists_file_s3.yml
```

## set pipeline

each foundation will set pipeline using per foundation configs from platform-automation-configuration. for example, pipeline for awstest can be set as following:
``` bash
fly -t auto sp -p "awstest-manage-products" \
-c ./manage-products.yml \
-l ../platform-automation-configuration/awstest/pipeline-vars/params.yml
```

