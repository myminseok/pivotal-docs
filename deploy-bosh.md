## 사전 준비
- [Setting up jumpbox](setup-bbl-sandbox.md)

## bosh-deployment clone
```
mkdir bosh-1
cd /home/pivotal/bosh-1
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


## test alias-env 
```
cd /home/pivotal/bosh-1
bosh alias-env d -e 10.10.10.200 --ca-cert <(bosh int creds.yml  --path /director_ssl/ca)

```

## set profile
```
cd /home/pivotal/bosh-1
bosh int creds.yml  --path /director_ssl/ca > director.crt

alias bosh='BOSH_CLIENT=admin BOSH_CLIENT_SECRET=xxxx BOSH_CA_CERT=/home/pivotal/bosh-1/director.crt BOSH_ENVIRONMENT=10.10.10.200 bosh '
```
