
# bosh-lite on Virtualbox
https://bosh.io/docs/bosh-lite/#install


# bosh on AWS
### prerequites: setup network topology(AWS)
```
my-vpc:(10.0.0.0/16)
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
#### deploy bosh 
https://bosh.io/docs/init-aws/#deploy

#### sample deploy on AWS
https://github.com/myminseok/pivotal-docs/blob/master/zookeeper-bosh-release.md

# bosh on Vsphere

https://bosh.io/docs/init-vsphere/

### preparation
- [Setting up jumpbox](setup-bbl-sandbox.md)

### prepare bosh-deployment manifest
```
mkdir -p ./workspace/bosh-1
cd ./workspace/bosh-1
git clone https://github.com/cloudfoundry/bosh-deployment
```
(optional: nsxt) https://bosh.io/docs/vsphere-cpi/#global
```
./cpi-with-nsxt.yml

- path: /cloud_provider/properties/vcenter/nsxt?
  type: replace
  value:
    host:
    username:
    password:
    ca_cert: |                                     
       ----- 
         
```
> nsxt.ca_cert:  
>> - openssl s_client -host NSX-ADDRESS -port 443 -prexit -showcerts
>> - https://docs.pivotal.io/platform/application-service/2-7/operating/vsphere-nsx-t.html#nsx-t-mode


vi deploy-bosh.sh
```
bosh create-env ./bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o ./bosh-deployment/vsphere/cpi.yml \
    -o ./bosh-deployment/misc/dns.yml  \  <-- for air-gapped env
    -o ./bosh-deployment/misc/ntp.yml  \  <-- for air-gapped env
    -o ./bosh-deployment/vsphere/resource-pool.yml \  <-- for resource pool
    -o ./cpi-nsxt.yml \                   <-- for nsxt
    -o ./bosh-deployment/jumpbox-user.yml \
    -o ./bosh-deployment/uaa.yml \
    -o ./bosh-deployment/credhub.yml \
    -v director_name=oss-bosh \
    -v internal_cidr=10.10.10.0/24 \
    -v internal_gw=10.10.10.1 \
    -v internal_ip=10.10.10.200 \
    -v internal_dns=[8.8.8.8] \
    -v internal_ntp=[time1.google.com] \
    -v network_name="VM Network" \
    -v vcenter_dc=datacenter \
    -v vcenter_rp=my-env-rp \
    -v vcenter_ds="^pcf\\-store$" \          <-- should be escaped with '\'
    -v vcenter_ip=10.10.10.10 \
    -v vcenter_user=administrator@vcenter.local \
    -v vcenter_password=PASSWORD \
    -v vcenter_templates=bosh-templates \
    -v vcenter_vms=oss-bosh-vms \
    -v vcenter_disks=oss-bosh-disks \
    -v vcenter_cluster=cluster1
```

### test bosh env
ubuntu@jumpbox:~/workspace/bosh-1$ cat bosh-env.txt
```
#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int $SCRIPT_DIR/creds.yml --path /admin_password`
bosh int $SCRIPT_DIR/creds.yml  --path /director_ssl/ca > $SCRIPT_DIR/director.ca
export BOSH_CA_CERT=$SCRIPT_DIR/director.ca
export BOSH_ENVIRONMENT=10.10.10.200

bosh int $SCRIPT_DIR/creds.yml  --path /jumpbox_ssh/private_key > $SCRIPT_DIR/jumpbox_ssh.key
chmod 600 $SCRIPT_DIR/jumpbox_ssh.key
echo "ssh -i $SCRIPT_DIR/jumpbox_ssh.key jumpbox@$BOSH_ENVIRONMENT" > $SCRIPT_DIR/ssh_jumpbox.sh
chmod +x $SCRIPT_DIR/ssh_jumpbox.sh

```

```
source bosh-env.txt
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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bosh int $SCRIPT_DIR/creds.yml --path /jumpbox_ssh/private_key > $SCRIPT_DIR/bosh-ssh.key
chmod 600 $SCRIPT_DIR/bosh-ssh.key
ssh -i $SCRIPT_DIR/bosh-ssh.key jumpbox@10.10.10.200
```

```
ubuntu@jumpbox:~/workspace/bosh-1$ ./ssh-bosh.sh
sudo ping 8.8.8.8
```


## cpi-config

```

```
## runtime-config

```
bosh update-runtime-config ./bosh-deployment/runtime-config/runtime-configs/dns.yml
```
or in air-gapped-env
```

$ cat local-release.yml

- type: replace
  path: /releases/name=bosh-dns/url
  value: file:///<PATH-TO-RELEASE>

  
bosh update-runtime-config ./bosh-deployment/runtime-config/runtime-configs/dns.yml -l ./local-release.yml

```



