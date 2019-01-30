

## Prepare for azure account (local Mac)
- https://portal.azure.com/

### install azure cli 

```
brew install azure-cli
```

### setup az account for PCF
- reference: https://docs.pivotal.io/pivotalcf/2-4/om/azure/prepare-env-manual.html
```
az login

az account list  ==> tenantId

az account set --subscription SUBSCRIPTION-ID

az ad app create ==> will create  appId==client_id

az ad sp create --id YOUR-APPLICATION-ID         ==> will create servicePrincipalNames

az role assignment create --assignee "SERVICE-PRINCIPAL-NAME" \
--role "Contributor" --scope /subscriptions/SUBSCRIPTION-ID

az login --username YOUR-APPLICATION-ID --password <CLIENT-PASS> --service-principal --tenant <TENANT-ID>

az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute

```

or  use az-automation https://github.com/genevieve/az-automation


## set azure env to bbl.
- https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/getting-started-azure.md

```
vi bbl-env.sh
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


## refrenence

- https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/advanced-configuration.md



