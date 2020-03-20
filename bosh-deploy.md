## 사전 준비
- [Setting up jumpbox](setup-bbl-sandbox.md)

## 사전준비: setup network topology(AWS)
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

## bosh-deployment clone
```
mkdir -p ./workspace/bosh-1
cd ./workspace/bosh-1
git clone https://github.com/cloudfoundry/bosh-deployment

```
## deploy manifest

```
cat deploy-bosh.sh

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


## deploy bosh


## test bosh env

ubuntu@ip-10-0-0-222:~/workspace/bosh-1$ cat setup-boshenv.sh
```
bosh int /home/ubuntu/workspace/bosh-1/creds.yml --path /director_ssl/ca > /home/ubuntu/workspace/bosh-1/bosh_director_ssl.ca
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int /home/ubuntu/workspace/bosh-1/creds.yml --path /admin_password`
export BOSH_CA_CERT=./bosh_director_ssl.ca
export BOSH_ENVIRONMENT=10.0.1.6

bosh env
```


## set to profile
vi ~/.profile
```
...
source /home/ubuntu/workspace/bosh-1/setup-boshenv.sh
```


## test outbound to internet inside of the bosh vm
```
ubuntu@ip-10-0-0-222:~/workspace/bosh-1$ cat ssh-bosh.sh
bosh int /home/ubuntu/workspace/bosh-1/creds.yml --path /jumpbox_ssh/private_key > /home/ubuntu/workspace/bosh-1/bosh-jumpbox-ssh.key
chmod 600 /home/ubuntu/workspace/bosh-1/bosh-jumpbox-ssh.key
ssh -i /home/ubuntu/workspace/bosh-1/bosh-jumpbox-ssh.key jumpbox@10.0.1.6



ubuntu@ip-10-0-0-222:~/workspace/bosh-1$ ssh-bosh.sh

sudo ping 8.8.8.8

```


