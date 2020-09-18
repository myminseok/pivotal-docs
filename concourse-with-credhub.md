
# concourse installation guide on AWS
This document explains how to install concourse cluster with separated credhub using concourse-bosh-release
- https://docs.pivotal.io/p-concourse/v5/#bosh-release
- https://docs.pivotal.io/p-concourse/v5/installation/install-concourse-bosh/
- https://docs.pivotal.io/p-concourse/v5/advanced/integrate-credhub-uaa-bosh/


## Prerequisites.
- [Setting up jumpbox](setup-bbl-sandbox.md)
- [Prepare bosh director vm](bosh-deploy.md)
- using bbl: https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/concourse.md

## setup bosh `vm extension` in cloud-config

##### case) set `vm extension` for OSS bosh
- define in cloud-config: https://bosh.io/docs/cloud-config/#vm-extensions
- and use it from manifest in `instance_groups` : https://bosh.io/docs/manifest-v2/

```
$ bosh cloud-config > bosh-cloud-config.yml

$ vi bosh-cloud-config.yml
vm_extensions:
- cloud_properties:
    disk: 102400
  name: 100GB_ephemeral_disk
  
$ bosh update-cloud-config ./bosh-cloud-config.yml
```

##### case) set `vm extension` using ops-manager

https://docs.pivotal.io/pivotalcf/2-6/customizing/custom-vm-extensions.html
```
curl -vv -k "https://localhost/api/v0/staged/vm_extensions" \
    -X POST \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "100GB_ephemeral_disk", "cloud_properties": { "disk": 102400 }}'

=> apply change

curl -k "https://localhost/api/v0/deployed/vm_extensions" \
    -X GET \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN"

```

## deploy concourse cluster
- https://docs.pivotal.io/p-concourse/v5/#bosh-release
- https://docs.pivotal.io/p-concourse/v5/installation/install-concourse-bosh/
- https://docs.pivotal.io/p-concourse/v5/advanced/integrate-credhub-uaa-bosh/
- https://github.com/myminseok/concourse-bosh-deployment-main

```
mkdir -p ~/workspace/concourse-bosh-deployment-main
cd ./workspace/concourse-bosh-deployment-main

git clone https://github.com/concourse/concourse-bosh-deployment
```

#### prepare concourse variables 

ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat variables.yml
```
---
local_user:
  username: admin
  password: 

deployment_name: concourse
db_persistent_disk_type: 10240
db_vm_type: medium.disk
external_url: https://concourse.pcfdemo.net   <--- concourse access url
external_host: concourse.pcfdemo.net
network_name: concourse
postgres_password: 
#web_ip: 10.10.10.210
web_vm_type: medium
#web_network_vm_extension: lb
worker_vm_type: xlarge.disk
worker_ephemeral_disk: 100GB_ephemeral_disk  <--- already set in bosh cloud-config
azs: [z1]
```



#### deploy concourse 'cluster' for HA


##### backup-and-restore-sdk
https://bosh.io/releases/github.com/cloudfoundry-incubator/backup-and-restore-sdk-release?version=1.15.0

```
bosh upload-release --sha1 b2d8584dd2ed964c4849cb6d7b536e6cea3e6e8d \
  https://bosh.io/d/github.com/cloudfoundry-incubator/backup-and-restore-sdk-release?v=1.15.0
```

#### upload stemcell to bosh director vm.
https://bosh.io/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent

```
bosh upload-stemcell --sha1 d77ced450b5bd7d9dc8562c5899ec723e67002fd \
  https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent?v=621.59
```

#### deploy concourse

```
source ~/workspace/bosh-1/setup-boshenv.sh
bosh deploy \
-d concourse ./concourse-bosh-deployment/cluster/concourse.yml \
-l ./concourse-bosh-deployment/versions.yml \
-l variables.yml \
--vars-store cluster-creds.yml \
-o ./concourse-bosh-deployment/cluster/operations/backup-atc.yml \
-o ./concourse-bosh-deployment/cluster/operations/basic-auth.yml \
-o ./concourse-bosh-deployment/cluster/operations/privileged-http.yml \
-o ./concourse-bosh-deployment/cluster/operations/privileged-https.yml \
-o ./concourse-bosh-deployment/cluster/operations/tls.yml \
-o ./concourse-bosh-deployment/cluster/operations/tls-vars.yml  \
-o ./concourse-bosh-deployment/cluster/operations/worker-ephemeral-disk.yml \
-o ./concourse-bosh-deployment/cluster/operations/web-network-extension.yml 

```
## integrate with credhub
- https://docs.pivotal.io/p-concourse/v5/advanced/integrate-credhub-uaa-bosh/

### concourse-credhub-vars.yml

```
bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret
```


```
credhub_url: "https://credhub.pcfdemo.net:8844"
credhub_client_id: "concourse_client"
credhub_client_secret: xxxx
credhub_ca_cert: |

```

```
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca  >> concourse-credhub-vars.yml
```



## test concourse

### fly cli download(linux):
```
wget https://github.com/concourse/concourse/releases/download/v5.4.1/fly-5.4.1-linux-amd64.tgz

```

### fly login

```

fly -t sandbox login -c <concourse elb url> -u <concourse user id> -p <concourse password> -k

ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ fly targets
name     url                            team  expiry
sandbox  http://concourse.pcfdemo.net   main  Sun, 22 Mar 2020 14:19:32 UTC

ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ fly -t sandbox status
logged in successfully


ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ fly -t sandbox workers
name                                  containers  platform  tags  team  state    version
295e21d1-5a12-4226-83fb-deac8d0a3915  0           linux     none  none  running  2.2


```

### sample concourse pipeline

https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/samples/hello-credhub.yml

```
jobs:
- name: hello-credhub
  plan:
  - do:
    - task: hello-credhub
      config:
        platform: linux
        image_resource:
          type: docker-image
          source:
            repository: ubuntu
        run:
          path: sh
          args:
          - -exc
          - |
            echo "Hello $WORLD_PARAM"
      params:
        WORLD_PARAM: {{hello}}
```

```
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat run-hello-credhub.sh
fly -t sandbox login -c http://concourse.pcfdemo.net -u admin -p xxxx -k
fly -t sandbox sp -p hello-credhub -c ./hello-credhub.yml -l hello="hello concourse!"
fly -t sandbox up -p hello-credhub
fly -t sandbox tj -j hello-credhub/hello-credhub -w

```
or check with web browser <concourse elb url>


### test concourse with credhub

### concourse cli download(linux):
```
wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.1.0/credhub-linux-2.1.0.tgz
tar xf credhub-linux-2.1.0.tgz

```

ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat ./login-credhub.sh
```
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://credhub.pcfdemo.net:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)
```

```
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ credhub api
https://credhub.pcfdemo.net:8844
```

```
$ credhub set -t value -n /concourse/main/hello-credhub/hello -v test

$ credhub get -n /concourse/main/hello-credhub/hello
id: 3cd51b78-426f-4145-b94e-baacf16c383d
name: /concourse/main/hello-credhub/hello
type: value
value: test

```


###  sample pipeline using credhub

https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/credhub-integration.md#sample-pipeline

https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/samples/hello-credhub.yml
```
jobs:
- name: hello-credhub
  plan:
  - do:
    - task: hello-credhub
      config:
        platform: linux
        image_resource:
          type: docker-image
          source:
            repository: ubuntu
        run:
          path: sh
          args:
          - -exc
          - |
            echo "Hello $WORLD_PARAM"
      params:
        WORLD_PARAM: ((hello))
```


```
ubuntu@jumpbox:~/workspace/concourse-bosh-deployment-main$ cat run-hello-credhub.sh
# login-credhub.sh
# credhub set -t value -n /concourse/main/hello-credhub/hello -v test
#fly -t sandbox login -c http://concourse.pcfdemo.net -u admin -p xxxx -k
fly -t sandbox sp -p hello-credhub -c ./hello-credhub.yml
fly -t sandbox up -p hello-credhub
fly -t sandbox tj -j hello-credhub/hello-credhub -w
 
```





## bind concourse user with PAS UAA
- [bind users in concourse with PAS](concourse_with_cf_auth.md)



## put web loadbalancer on concourse web
you can bind web VM to load-balancer automatically using vm_extensions setting in bosh cloud-config which has different configuration per IAAS. ex)  https://bosh.io/docs/aws-cpi/#resource-pools

#### prepare external loadbalancer (elb)
```
- name: concourse-lb
- HTTP 80
- HTTPS 443
- TCP 8443 
- TCP 8844
```

#### set `vm extension` for concourse web loadbalancer.

##### case) set `vm extension` for OSS bosh
- define in cloud-config: https://bosh.io/docs/cloud-config/#vm-extensions
- and use it from manifest in `instance_groups` : https://bosh.io/docs/manifest-v2/

```
$ bosh cloud-config > bosh-cloud-config.yml

$ vi bosh-cloud-config.yml
vm_extensions:
- cloud_properties:
    elbs: "[concourse-lb]"
  name: lb
  
$ bosh update-cloud-config ./bosh-cloud-config.yml
```

##### case) set `vm extension` using ops-manager

https://docs.pivotal.io/pivotalcf/2-6/customizing/custom-vm-extensions.html
```

curl -vv -k "https://localhost/api/v0/staged/vm_extensions" \
    -X POST \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "lb", "cloud_properties": { "elbs": "[concourse-lb]" }}'

=> apply change

curl -k "https://localhost/api/v0/deployed/vm_extensions" \
    -X GET \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN"

```


#### deploy concourse with the load-balancer 

```
bosh deploy -n --no-redact -d concourse concourse.yml \
 ...
  -o operations/web-network-extension.yml \
  ...
  --var web_network_vm_extension=lb \
```
