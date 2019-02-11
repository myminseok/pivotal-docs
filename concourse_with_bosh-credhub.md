
## concourse and bosh-credhub

###  bosh deployment script 

#### concourse v3.14.1.0 on aws 

#### add credhub user to bosh uaa
```
3) create uaac client https://docs.cloudfoundry.org/uaa/uaa-user-management.html

$ uaac target https://10.0.0.6:8443 --skip-ssl-validation
$ uaac token client get uaa_admin -s <uaa password> => password는 bbl > vars/director_vars_store.yaml참조

사용자 추가시 권한 참조: https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/credhub-integration.md#uaa-client-setup

$ uaac client add concourse_to_credhub --authorities "credhub.read,credhub.write" --scope "" --authorized-grant-types "client_credentials"

bosh credhub test
jumpbox로 ssh 접속
download credhub cli: https://github.com/cloudfoundry-incubator/credhub-cli/releases
$ ./credhub api -s https://10.0.0.6:8844 --ca-cert ./credhub.ca --skip-tls-validation
$ ./credhub login --client-name=concourse_to_credhub --client-secret=<credhub password>  => credhub인증정보는 bbl > vars/director_vars_store.yaml참조


```

#### deploy
vi deploy.sh
~~~
export concourse_elb=<concourse elb url>

bosh deploy -n --no-redact -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store cluster-creds.yml \
  -o operations/basic-auth.yml \
  -o operations/privileged-http.yml \
  -o operations/privileged-https.yml \
  -o operations/tls.yml \
  -o operations/tls-vars.yml \
  -o operations/web-network-extension.yml \
  -o operations/scale.yml \
  -o operations/static-db.yml \
  -o operations/worker-ephemeral-disk.yml \
  -o operations/credhub.yml \
  --var network_name=private \
  --var external_host=$concourse_elb \
  --var external_url=https://$concourse_elb \
  --var web_vm_type=default \
  --var db_vm_type=default \
  --var db_persistent_disk_type=10GB \
  --var worker_ephemeral_disk=100GB_ephemeral_disk \
  --var worker_vm_type=default \
  --var web_instances=1 \
  --var worker_instances=1 \
  --var deployment_name=concourse \
  --var web_network_name=private \
  --var web_network_vm_extension=lb \
  --var local_user.username=admin \
  --var local_user.password=<비밀번호> \
  --var atc_basic_auth.username=admin \
  --var atc_basic_auth.password=<비밀번호> \
  --var external_lb_common_name=$concourse_elb \
  --var concourse_host=$concourse_elb \
  --var db_ip=10.0.31.190 \
  --var credhub_url=https://10.0.0.6:8844 \
  --var credhub_client_id=concourse_to_credhub \
  --var credhub_client_secret=<비밀번호> \
  -l ./credhub_ca.ca


  
  # worker_ephemeral_disk: bosh cloud-config에서 나온 값을 입력
  # db_ip: bosh cloud-config에서 나온 private network의 값중 static_ip의 pool에서 하나를 선택.
  # credhub_url: bbl director-address
  # credhub_client_id, credhub_client_secret: 앞에서 추가한 사용자정보
  # credhub_ca.ca파일:
    eval "$(bbl print-env)"
    bosh int ./vars/director_vars_stores.yml --path /credhub_ca/ca > credhub_ca.ca
    위 명령으로 credhub인증서를 추출한 후 아래 포맷으로 credhub_ca.ca 파일에 저장.
    credhub_ca_cert: |
      ----- BEGIN xxx-----
      xxxx
      ---- END xxx-----
    chmod 600 credhub_ca.ca 
~~~


#### concourse 4.1.0 on vsphere 
~~~
export concourse_url=https://<concourse url>

bosh -e d deploy -n --no-redact -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store cluster-creds.yml \
  -o operations/basic-auth.yml \
  -o operations/privileged-http.yml \
  -o operations/privileged-https.yml \
  -o operations/tls.yml \
  -o operations/tls-vars.yml \
  -o operations/scale.yml \
  -o operations/static-web.yml \
  -o operations/cf-auth.yml \
  --var web_ip=10.10.10.210 \
  --var network_name=concourse \
  --var external_url=https://<concourse url> \
  --var web_vm_type=medium \
  --var db_vm_type=medium.disk \
  --var worker_vm_type=large.disk \
  --var db_persistent_disk_type=db \
  --var web_instances=1 \
  --var worker_instances=1 \
  --var deployment_name=concourse \
  --var external_lb_common_name=<concourse url> \
  --var external_host=<concourse url> \
  --var concourse_host=<concourse url> \
  --var local_user.username=admin \
  --var local_user.password=<password>

~~~


  
