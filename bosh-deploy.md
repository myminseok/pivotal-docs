
# bosh-lite on virtualbox
https://bosh.io/docs/bosh-lite/#install


# bosh on aws
### 사전준비: setup network topology(AWS)
```
my-vpc:
- Subnets:
  - subnet-public-1(10.0.0.0/24):
       - jumpbox vm (=> bind to public IP or EIP)
  - subnet-private-1(10.0.1.0/24):
       - bosh vm
   
- Internet gateways: 
  - igw-1 (=> attach to vpc)
    
- NAT gateways:
  - nat-gw-1 (=> select "subnet-public", => bind to EIP )

- Route tables:     
  - route_table_public_1:
    - route table:
      - 0.0.0.0/0 -> igw-1
    - subnet associations:
      - subnet-public-1
      
  - route_table_private_1:
    - route table:
     - 0.0.0.0/0 -> nat-gw-1
    - subnet associations:
      - subnet-private-1

```

# bosh on vsphere

https://bosh.io/docs/init-vsphere/

### preparation
- [Setting up jumpbox](setup-bbl-sandbox.md)

### prepare bosh-deployment manifest
```
mkdir -p ./workspace/bosh-1
cd ./workspace/bosh-1
git clone https://github.com/cloudfoundry/bosh-deployment
```

vi deploy-bosh.sh
```
bosh create-env ./bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o ./bosh-deployment/vsphere/cpi.yml \
    -o ./bosh-deployment/jumpbox-user.yml \
    -o ./bosh-deployment/uaa.yml \
    -o ./bosh-deployment/misc/config-server.yml \
    -v director_name=bosh \
    -v internal_cidr=10.10.10.0/24 \
    -v internal_gw=10.10.10.1 \
    -v internal_ip=10.10.10.200 \
    -v network_name="VM Network" \
    -v vcenter_dc=datacenter \
    -v vcenter_ds=pcfstore \
    -v vcenter_ip=10.10.10.10 \
    -v vcenter_user=administrator@vcenter.local \
    -v vcenter_password=PASSWORD \
    -v vcenter_templates=bosh-templates \
    -v vcenter_vms=bosh-vms \
    -v vcenter_disks=bosh-disks \
    -v vcenter_cluster=cluster1
```

### test bosh env
ubuntu@jumpbox:~/workspace/bosh-1$ cat setup-boshenv.sh
```
#!/bin/bash
BIN_DIR=$(cd $(dirname $0); pwd)
echo $BIN_DIR

bosh int $BIN_DIR/creds.yml  --path /director_ssl/ca > $BIN_DIR/director.ca
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int $BIN_DIR/creds.yml --path /admin_password`
export BOSH_CA_CERT=$BIN_DIR/director.ca
export BOSH_ENVIRONMENT=10.10.10.200
```

```
ubuntu@jumpbox:~/workspace/bosh-1$ bosh env
Using environment '10.10.10.200' as client 'admin'

Name               bosh-mkim
UUID               d66d286c-4717-471e-ab8b-5b419a937a43
Version            270.12.0 (00000000)
Director Stemcell  ubuntu-xenial/621.59
CPI                vsphere_cpi
Features           compiled_package_cache: disabled
                   config_server: enabled
                   local_dns: enabled
                   power_dns: disabled
                   snapshots: disabled
User               admin

Succeeded
```


## set to profile
vi ~/.profile
```
...
source /home/ubuntu/workspace/bosh-1/setup-boshenv.sh
```


## test outbound to internet inside of the bosh vm
ubuntu@jumpbox:~/workspace/bosh-1$ cat ssh-bosh.sh
```
bosh int /home/ubuntu/workspace/bosh-1/creds.yml --path /jumpbox_ssh/private_key > /home/ubuntu/workspace/bosh-1/bosh-jumpbox-ssh.key
chmod 600 /home/ubuntu/workspace/bosh-1/bosh-jumpbox-ssh.key
ssh -i /home/ubuntu/workspace/bosh-1/bosh-jumpbox-ssh.key jumpbox@10.10.10.200
```

```
ubuntu@jumpbox:~/workspace/bosh-1$ ./ssh-bosh.sh
sudo ping 8.8.8.8
```


## cpi-config

```

```
## cloud-config
ubuntu@jumpbox:~/workspace/bosh-1$ cat runtime-config.yml
```
---
addons:
- include:
    stemcell:
    - os: ubuntu-xenial
  name: bosh-dns
  jobs:
  - name: bosh-dns
    release: bosh-dns
    properties:
      api:
        client:
          tls:
            ca: "((/dns_api_client_tls.ca))"
            certificate: "((/dns_api_client_tls.certificate))"
            private_key: "((/dns_api_client_tls.private_key))"
        server:
          tls:
            ca: "((/dns_api_server_tls.ca))"
            certificate: "((/dns_api_server_tls.certificate))"
            private_key: "((/dns_api_server_tls.private_key))"
      cache:
        enabled: true
      health:
        client:
          tls: "((/bosh_dns_health_client_tls))"
        enabled: true
        server:
          tls: "((/bosh_dns_health_server_tls))"
      override_nameserver: false
releases:
- name: bosh-dns
  version: 1.19.0
variables:
- name: "/bosh_dns_health_tls_ca"
  options:
    common_name: bosh-dns-health-tls-ca
    is_ca: true
  type: certificate
- name: "/bosh_dns_health_server_tls"
  options:
    ca: "/bosh_dns_health_tls_ca"
    common_name: health.bosh-dns
    extended_key_usage:
    - server_auth
  type: certificate
- name: "/bosh_dns_health_client_tls"
  options:
    ca: "/bosh_dns_health_tls_ca"
    common_name: health.bosh-dns
    extended_key_usage:
    - client_auth
  type: certificate
- name: "/dns_api_server_tls"
  options:
    ca: "/bosh_dns_health_tls_ca"
    common_name: api.bosh-dns
    extended_key_usage:
    - server_auth
  type: certificate
- name: "/dns_api_client_tls"
  options:
    ca: "/bosh_dns_health_tls_ca"
    common_name: api.bosh-dns
    extended_key_usage:
    - client_auth
  type: certificate
  
```
```
bosh update-runtime-config ./runtime-config.yml

```





