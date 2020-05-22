
#  How to set secrets to concourse credhub

## prerequisits
- [prepare concourse cluster with credhub](/concourse-with-credhub.md)

####  download credhub cli: 
- https://github.com/cloudfoundry-incubator/credhub-cli/releases

####  login to credhub
``` bash
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat login-credhub.sh
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://credhub.pcfdemo.net:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)

platform-automation-template/awstest/pipeline-vars/set-credhub.sh
```

#### set pipeline secrets to credhub
- [set pipeline secrets to credhub](/platform-automation/set-pipeline-params.md)
- refer to [sample code set-credhub.sh](https://github.com/myminseok/platform-automation-template/blob/master/dev/pipeline-vars/setenv-credhub.sh)


## secrets per each foundation from terraform state file
- after terraforming, there is terraform.tfstate file. https://docs.pivotal.io/platform/2-7/customizing/aws-terraform.html
- [sample code set-credhub-from-terraform.sh](https://github.com/myminseok/platform-automation-template/awstest/pipeline-vars/set-credhub-from-terraform.sh)
- please note that pipelie specific variables will have a path of `/concourse/main/<PIPELINE_NAME>/...`
``` bash

#!/bin/bash

if [ -z $1 ] || [ -z $2 ] ; then
    echo "please provide parameters"
	echo "${BASH_SOURCE[0]} PIPELINE_NAME TERRAFORM_STATE_FILE_PATH"
	exit
fi

PIPELINE_NAME=$1
TERRAFORM_STATE_FILE_PATH=$2

PREFIX='/concourse/main'


if [ ! -f "$TERRAFORM_STATE_FILE_PATH" ]; then
  echo "Required terraform state file does not exist: $TERRAFORM_STATE_FILE_PATH'"
  exit 1
fi

function set_value(){
    local KEY=$1
    value=`terraform output -state ${TERRAFORM_STATE_FILE_PATH} ${KEY}`
    credhub set -t value -n ${PREFIX}/${PIPELINE_NAME}/${KEY} -v "$value"
}

function set_password(){
    local KEY=$1
    value=`terraform output -state ${TERRAFORM_STATE_FILE_PATH} ${KEY}`
    credhub set -t password -n ${PREFIX}/${PIPELINE_NAME}/${KEY} -w "$value"
}

function set_first_value_from_array(){
    local KEY=$1
    value=`terraform output -state ${TERRAFORM_STATE_FILE_PATH} ${KEY} | awk -F',' '{print $1}' | head -n 1`
    credhub set -t value -n ${PREFIX}/${PIPELINE_NAME}/${KEY} -v "$value"
}


function set_ssh_private_key(){
    local KEY=$1
    terraform output -state ${TERRAFORM_STATE_FILE_PATH} ${KEY}  > ./tmp_set_ssh_private_key
    credhub delete -n ${PREFIX}/${PIPELINE_NAME}${KEY}
    credhub set -t rsa -n ${PREFIX}/${PIPELINE_NAME}/${KEY} -p ./tmp_set_ssh_private_key
}

## for opsman.yml , director.yml
set_first_value_from_array "public_subnet_ids" ##  module.infra.public_subnet_ids, 0
set_value "ops_manager_security_group_id"
set_value "ops_manager_ssh_public_key_name"
set_value "ops_manager_iam_instance_profile_name"
set_value "ops_manager_public_ip"
set_ssh_private_key "ops_manager_ssh_private_key"
set_value "ops_manager_iam_user_access_key"
set_password "ops_manager_iam_user_secret_key"
set_value "vms_security_group_id"
#set_value "rds_address"
#set_value "rds_username"
#set_password "rds_password"

```

#### (optional) you can generate a self-signed domain certificate from TAS tile
1. generate certs from opsmanager UI> PAS> networking
2. copy certifiate to "domain.crt" file
3. copy private key to "domain.key" file.
4. set domain certs and keys to credhub   
   
#### (optional) how to extract secret value from PAS
``` bash
root@d50b90c0-7288-4194-5611-4799d7ad34ea:/tmp/build/4a564f8b# om --env ./env/dkpcf/env/env.yml credential-references -p cf | grep poe
| .properties.networking_poe_ssl_certs[0].certificate


root@d50b90c0-7288-4194-5611-4799d7ad34ea:/tmp/build/4a564f8b# om --env ./env/dkpcf/env/env.yml credentials -p cf -c .properties.networking_poe_ssl_certs[0].certificate
+------------------------------------------------------------------+------------------------------------------------------------------+
| cert_pem | private_key_pem |
+------------------------------------------------------------------+------------------------------------------------------------------+
| | -----BEGIN RSA PRIVATE -----
| MIIEpAIBAAKCAQEA1Xu8fbAMsJpjIQYRQ1Kv6L2R1ZpB1/i74tIj3SHtKs76Yss1
...
|AZokZDWW5Lb3eKoAInGbQ9tsfrJeADL0jSINt/2bIF1QA7g==l+wctiD
| -----END RSA PRIVATE -----
```


or use tile-config-generator to get cf.yml template(template only)
- https://github.com/pivotalservices/tile-config-generator


