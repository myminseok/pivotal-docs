
### guide
- https://docs.pivotal.io/p-concourse/v5/installation/install-concourse-bosh/#set-up-a-deployment
- https://docs.pivotal.io/p-concourse/v5/advanced/integrate-credhub-uaa-bosh/#deploy-credhub-uaa


### Setup concourse-bosh-deployment directory on your local machine
guide: - https://docs.pivotal.io/p-concourse/v5/installation/install-concourse-bosh/#set-up-a-deployment

```

mkdir concourse-bosh-deployment-main
cd concourse-bosh-deployment-main

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main
git clone https://github.com/concourse/concourse-bosh-deployment.git

cd concourse-bosh-deployment
git checkout v5.5.7



```

### Download & Upload Concourse Release

```
bosh -e BOSH-ENVIRONMENT upload-release ~/Downloads/concourse-bosh-release-5.5.7.tgz
```

upload missing release
```cluster/operations/backup-atc.yml
   value:
     name: backup-and-restore-sdk
     version: ((bbr_sdk_version))
     url: https://bosh.io/d/github.com/cloudfoundry-incubator/backup-and-restore-sdk-release?v=((bbr_sdk_version))
```
bump up bpm version
- 1.1.3 has bug
```versions.yml
 ---
 concourse_version: '5.5.7'
 concourse_sha1: '9ccad01fb96fcd115f882bc82f373724b52be514'
#bpm_version: '1.1.3'
#bpm_sha1: 'b41556af773ea9aec93dd21a9bbf129200849eed'
bpm_version: '1.1.6'
bpm_sha1: '5bad6161dbbcf068830a100b6a76056fe3b99bc8'
```

### prepare concourse deployment
ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main
```

variables.yml
---
local_user:
  username: admin
  password: PASSWORD

deployment_name: concourse
db_persistent_disk_type: 10240
db_vm_type: medium.disk
external_url: https://CONCOURSE-URL
external_host: CONCOURSE-URL
network_name: infra-network
postgres_password: PASSWORD
web_ip: 10.10.10.210
web_vm_type: medium
worker_vm_type: xlarge.disk

```

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main

``` deploy-concourse.sh
export BOSH_CLIENT=ops_manager  BOSH_CLIENT_SECRET=xxxx BOSH_CA_CERT=/var/tempest/workspaces/default/root_ca_certificate BOSH_ENVIRONMENT=10.10.10.21

bosh deploy \
-d concourse ./concourse-bosh-deployment/cluster/concourse.yml \
-l versions.yml \
-l variables.yml \
--vars-store cluster-creds.yml \
-o ./concourse-bosh-deployment/cluster/operations/backup-atc.yml \
-o ./concourse-bosh-deployment/cluster/operations/basic-auth.yml \
-o ./concourse-bosh-deployment/cluster/operations/privileged-http.yml \
-o ./concourse-bosh-deployment/cluster/operations/static-web.yml \
-o ./concourse-bosh-deployment/cluster/operations/privileged-https.yml \
-o ./concourse-bosh-deployment/cluster/operations/tls.yml \
-o ./concourse-bosh-deployment/cluster/operations/tls-vars.yml 
```

### test login to concourse
```
fly -t <choose a target name> login -c https://<web_ip> -u <username> -p <password>.
```



### Deploy Credhub & UAA
- guide: https://docs.pivotal.io/p-concourse/v5/advanced/integrate-credhub-uaa-bosh/#deploy-credhub-uaa


```
ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ cat credhub-vars.yml
---
deployment-network: infra-network
external-ip-address: 10.10.10.211
internal-ip-address: 10.10.10.211
db_host: localhost
db_port: 5432
uaa_external_url: "https://10.10.10.211:8443"
uaa_internal_url: "https://10.10.10.211:8443"
uaa_version: "74.9.0"
uaa_sha1: "9647fff0fcb249e71ba2290849b4cdbbf7550165"
credhub_version: "2.5.7"
credhub_sha1: "9647fff0fcb249e71ba2290849b4cdbbf7550165"
postgres_version: "39"
postgres_sha1: "8ff395540e77a461322a01c41aa68973c10f1ffb"
bpm_version: '1.1.6'
bpm_sha1: '5bad6161dbbcf068830a100b6a76056fe3b99bc8'
```

#### Create a new manifest. For example, with vim:
vim credhub-uaa-manifest.yml
```

```

#### deploy credhub

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main

``` deploy-credhub.sh
export BOSH_CLIENT=ops_manager  BOSH_CLIENT_SECRET=xxxx BOSH_CA_CERT=/var/tempest/workspaces/default/root_ca_certificate BOSH_ENVIRONMENT=10.10.10.21

bosh  deploy -d credhub-uaa credhub-uaa-manifest.yml \
  --vars-file credhub-vars.yml \
  --vars-store credhub-vars-store.yml
```


### test credhub.
```
ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ cat login-credhub.sh
bosh int ./credhub-vars-store.yml --path=/credhub-ca/ca > credhub-ca.ca
credhub api --server=https://10.10.10.211:8844 --ca-cert=./credhub-ca.ca
credhub login  --client-name=concourse_client --client-secret=$(bosh int ./credhub-vars-store.yml --path=/concourse_credhub_client_secret)
```

```
ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ ./login-credhub.sh
Setting the target url: https://10.10.10.211:8844
Login Successful

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ credhub set -t value -n /concourse/main/hello-credhub/hello -v test

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ credhub find
credentials:
- name: /concourse/main/hello-credhub/hello
  version_created_at: "2020-03-08T07:21:32Z"

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ credhub get -n /concourse/main/hello-credhub/hello
id: 3fefc9f3-f0ca-4139-ab58-670d1410ef08
name: /concourse/main/hello-credhub/hello
type: value
value: test
version_created_at: "2020-03-08T07:21:32Z"
```


### Integrate Concourse with Credhub



### prepare concourse deployment
ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main
```

variables.yml
---
local_user:
  username: admin
  password: PASSWORD

...

credhub_url: "https://CREDHUB-IP:8844"
credhub_client_id: "concourse_client"
credhub_client_secret: "xxxxxxxx"
credhub_ca_cert: |
  -----BEGIN CERTIFICATE-----
  xxx
  -----END CERTIFICATE----- 
```

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main

``` deploy-concourse.sh
export BOSH_CLIENT=ops_manager  BOSH_CLIENT_SECRET=xxxx BOSH_CA_CERT=/var/tempest/workspaces/default/root_ca_certificate BOSH_ENVIRONMENT=10.10.10.21

bosh deploy \
-d concourse ./concourse-bosh-deployment/cluster/concourse.yml \
-l versions.yml \
-l variables.yml \
--vars-store cluster-creds.yml \
...

-o ./concourse-bosh-deployment/cluster/operations/tls-vars.yml \
-o ./concourse-bosh-deployment/cluster/operations/credhub.yml

```


###Verify Integration
``` ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ cat hello-credhub.yml

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
credhub set -t value -n /concourse/main/hello-credhub/hello -v test

fly -t sandbox login -c http://CONCOURSE-URL -u admin -p <PASSWORD> -k

fly -t sandbox sp -p hello-credhub -c ./hello-credhub.yml
fly -t sandbox up -p hello-credhub

ubuntu@opsmanager-2-8:~/concourse-bosh-deployment-main$ fly -t sandbox tj -j hello-credhub/hello-credhub -w
started hello-credhub/hello-credhub #6

initializing
running sh -exc echo "Hello $WORLD_PARAM"

+ echo Hello test
Hello test
succeeded


fly -t sandbox watch -j hello-credhub/hello-credhub
```



