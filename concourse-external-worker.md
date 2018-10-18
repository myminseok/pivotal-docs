# update bosh cloud-config for disk, vm-type(100GB ephemeral)

```
ssh into ops manager

bosh -e d cloud-config > cloud-config.yml
vi cloud-config.yml

vm_extensions:
- cloud_properties:
    ephemeral_disk:
      size: 102400
      type: gp2
  name: 100GB_ephemeral_disk
bosh -e d update-cloud-config  ./cloud-config.yml

ubuntu@ip-192-168-0-7:~$ bosh -e d cloud-config | grep 100G
  name: 100GB_ephemeral_disk
  
 ```
 
# prepare external concourse bosh deployment script (deploy_external_worker.sh)
reference: https://github.com/concourse/concourse-bosh-deployment/tree/master/cluster

```
ssh into control-plane jumbox to get concourse tsa-credentials.

cd jumpbox/0:~/control-plane/concourse-bosh-deployment/cluster

bosh int ./cluster-creds.yml --path=/tsa_host_key > external-worker-secret.yml
bosh int ./cluster-creds.yml --path=/worker_key >> external-worker-secret.yml
```
```
vi external-worker-secret.yml 

tsa_host_key:
  public_key: <public_key>

worker_key:
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
```

# deploy external concourse external worker

```
ssh into ops manager

git clone https://github.com/concourse/concourse-bosh-deployment/

bosh -e d deploy -d concourse-external-worker external-worker.yml \
  -l ../versions.yml \
  -o operations/worker-ephemeral-disk.yml \
  -v external_worker_network_name=infrastructure \
  -v worker_vm_type=m4.large \
  -v instances=1 \
  -v azs=[ap-northeast-2a] \
  -v deployment_name=concourse-external-worker \
  -v tsa_host=<concourse-web-url> \ # no https:// , no trailing slash.
  -v worker_tags=[pcf-dev-worker] \
  -v worker_ephemeral_disk=100GB_ephemeral_disk \
  -l ./external-worker-secret.yml
```

# after deployment, checkout if the worker is registered on concourse
```
fly  -t cp-1 workers)
```
