
```
ubuntu@opsman:~$ cat opsman-env.yml 
target: ((opsman_target))
connect-timeout: 30                 # default 5
request-timeout: 3600               # default 1800
skip-ssl-validation: true           # default false
username: ((opsman_admin.username))
password: ((opsman_admin.password))

```


```
ubuntu@opsman:~$ wget https://github.com/pivotal-cf/om/releases/download/4.6.0/om-linux-4.6.0
chmod +x om-linux-4.6.0
sudo mv ./om-linux-4.6.0 /usr/local/bin/om
```

#### download pas tile from network.pivotal.io

```
# cf-2.8.3-build.20.pivotal
# pivnet download-product-files --product-slug='elastic-runtime' --release-version='2.8.3' --product-file-id=600570

om -e opsman-env.yml download-product \
--pivnet-api-token='b57375fe32624dc997fb5ccea4b544e9-r' \
--pivnet-product-slug='elastic-runtime' \
--product-version='2.8.3' \
--file-glob='cf-*-build.20.pivotal' \
--output-directory .

```


### download stemcell for PAS tile
```
# pivnet download-product-files --product-slug='stemcells-ubuntu-xenial' --release-version='621.61' --product-file-id=643032

om -e opsman-env.yml download-product \
--pivnet-api-token='b57375fe32624dc997fb5ccea4b544e9-r' \
--pivnet-product-slug='stemcells-ubuntu-xenial' \
--product-version='621.61' \
--file-glob='light-bosh-stemcell-621.61-aws-xen-hvm-ubuntu-xenial-go_agent.tgz' \
--output-directory .

```



#### upload pas tile to opsman UI.
```
om -e opsman-env.yml upload-product --product ./cf-2.8.3-build.20.pivotal
```

#### upload stemcell for pas
```
om -e opsman-env.yml  upload-stemcell --stemcell  ./light-bosh-stemcell-621.61-aws-xen-hvm-ubuntu-xenial-go_agent.tgz 
```



