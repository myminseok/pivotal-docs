# terraforming on aws

## docs
- https://docs.pivotal.io/ops-manager/2-10/aws/prepare-env-terraform.html
- https://github.com/pivotal/paving 
- (deprecated) https://network.pivotal.io/products/elastic-runtime/#/releases/668407 ( 2.6)

## download terraform cli.
https://www.terraform.io/downloads.html
```
brew install terraform
```
```
terraform version 
```

## clone repo 
```
git clone https://github.com/pivotal/paving
```

## remove needless files
```
cd paving/aws/

rm -rf pks-*
```



## edit terraform.tfvars
```
cp terraform.tfvars.example terraform.tfvars

vi terraform.tfvars

-----------
environment_name = "tas-test"

access_key = "xxxx"
secret_key = "xxxx"

region = "ap-northeast-2"
availability_zones = ["ap-northeast-2a","ap-northeast-2b","ap-northeast-2c"]

hosted_zone = "pcfdemo.net."
-----------
```

## terraforming
```
terraform init

terraform plan | tee _output

# review  _output 

```

## terraform apply
```
terraform apply

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

tls_private_key.ops-manager: Creating...
random_integer.ops_manager_bucket_suffix: Creating...
random_integer.pas_bucket_suffix: Creating...

....

Apply complete! Resources: 93 added, 0 changed, 0 destroyed.
```
backup terraform.tfstate to the safe place.


## extract output

```
terraform output  -state=./terraform.tfstate stable_config_opsmanager  | sed 's/}"/}/g' | sed 's/^"//g' | sed 's/\\"/"/g' | jq . > tmp_stable_config_opsmanager
```
```
terraform output  -state=./terraform.tfstate  stable_config_pas   | sed 's/}"/}/g' | sed 's/^"//g' | sed 's/\\"/"/g'  | jq . > tmp_stable_config_pas
```

### extract ops_manager_ssh_private_key
```
jq .ops_manager_ssh_private_key ./tmp_stable_config_opsmanager > tmp_ops_manager_ssh_private_key
```
```
cat tmp_ops_manager_ssh_private_key
"-----BEGIN RSA PRIVATE KEY-----\\nMIIJKAIBAAKCAgEAtb1NeLOuvr60IZfEUcZU
...
hCHX8rL6Zwb\\n1rf\\n-----END RSA PRIVATE KEY-----\\n"
```


# copy the output and paste to printf command including the double quote
```
printf -- PASTE_THE_SSH_KEY_CONTENT > ops_manager_ssh_private_key
```


