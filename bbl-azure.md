Local PC에 bbl을 위한 환경을 설정하는 것을 설명합니다.
참고 문서: https://github.com/cloudfoundry/bosh-bootloader

## azure cli 
https://docs.pivotal.io/pivotalcf/2-2/om/azure/prepare-env-manual.html
https://portal.azure.com/
```
brew install azure-cli
```

## for azure account

- reference: https://docs.pivotal.io/pivotalcf/2-4/om/azure/prepare-env-manual.html
- https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/getting-started-azure.md

```
az account list  ==> tenantId
az ad app create ==> will create  appId==client_id

az ad sp create --id YOUR-APPLICATION-ID         ==> will create servicePrincipalNames

az role assignment create --assignee "SERVICE-PRINCIPAL-NAME" \
--role "Contributor" --scope /subscriptions/SUBSCRIPTION-ID

az login --username YOUR-APPLICATION-ID --password <CLIENT-PASS> --service-principal --tenant <TENANT-ID>

```
Local PC에 bbl을 위한 환경을 설정하는 것을 설명합니다.
참고 문서: https://github.com/cloudfoundry/bosh-bootloader

## prepare for azure account

reference: https://docs.pivotal.io/pivotalcf/2-4/om/azure/prepare-env-manual.html
https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/getting-started-azure.md

```
az login
az account list  ==> tenantId
az ad app create ==> will create  appId==client_id

az ad sp create --id YOUR-APPLICATION-ID         ==> will create servicePrincipalNames

az role assignment create --assignee "SERVICE-PRINCIPAL-NAME" \
--role "Contributor" --scope /subscriptions/SUBSCRIPTION-ID

az login --username YOUR-APPLICATION-ID --password <CLIENT-PASS> --service-principal --tenant <TENANT-ID>

```


## set azure env to bbl.

vi bbl-env.sh

```
export BBL_IAAS=azure
export BBL_AZURE_CLIENT_ID=
export BBL_AZURE_CLIENT_SECRET=
export BBL_AZURE_REGION=
export BBL_AZURE_SUBSCRIPTION_ID=
export BBL_AZURE_TENANT_ID=

```

## bbl up

```
source bbl-env.sh

bbl up --lb-type concourse
```

## load bbl env after bbl up.

```
eval "$(bbl print-env)"

bbl lbs

```






참고: https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/advanced-configuration.md
참고: https://github.com/myminseok/bbl-template


