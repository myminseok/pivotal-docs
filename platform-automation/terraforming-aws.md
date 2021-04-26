# terraforming on aws

## docs
- https://docs.pivotal.io/ops-manager/2-10/aws/prepare-env-terraform.html
- https://github.com/pivotal/paving 
- (deprecated) https://network.pivotal.io/products/elastic-runtime/#/releases/668407 ( 2.6)

## download terraform cli.
https://www.terraform.io/downloads.html
```
terraform version 
+ 0.13+ 
```

## 
```
git clone https://github.com/pivotal/paving

cd paving/aws/

cp terraform.tfvars.example terraform.tfvars

vi terraform.tfvars

terraform init

terraform plan -var-file terraform.tfvars -out=_plan | tee _output

vi _output 

```
