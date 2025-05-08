## Uploading a stemcell via opsmanager API

1. Get opsman uaa access token
```
ubuntu@opsmanager-3-0:~$  uaac target https://YOUR-OPS-MANAGER-URL.com/uaa --skip-ssl-validation

ubuntu@opsmanager-3-0:~$ uaac token owner get
Client ID:  opsman
Client secret:
User name:  admin  <-- portal account
Password:  ********  <-- portal password


ubuntu@opsmanager-3-0:~$ uaac contexts
[0] [https://uaa.sys.lab.pcfdemo.net]
  ca_cert: /var/tempest/workspaces/default/root_ca_certificate

  [0] [admin]
      client_id: admin
      access_token: eyJqa3UiOiJodHRwczovL3VhYS5zeXMubGFiLnBjZmRlbW8ubmV0L3Rva2VuX2tleXMiLCJraWQiOiJrZXktMSIsInR5cCI6IkpXVCIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJhZG1pbiIsImlzcyI6Imh0dHBzOi8vdWFhLxxx



ubuntu@opsmanager-3-0:~$  export TOKEN="eyJqa3UiOiJodHRwczovL3VhYS5zeXMubGFiLnBjZmRlbW8ubmV0L3Rva2VuX2tleXMiLCJraWQiOiJrZXktMSIsInR5cCI6IkpXVCIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJhZG1pbiIsImlzcyI6Imh0dHBzOi8vdWFhLxxx"


export TOKEN="xxx"
export OPSMAN_IP=""
curl -k https://$OPSMAN_IP/api/v0/diagnostic_report   -H "Authorization: Bearer $TOKEN"  

```

2. upload stemcell

during the api call, there is no output until it uploads completely. check logs from opsman vm under /var/log/opsmanager/production.log

```
curl "https://$OPSMAN_IP/api/v0/stemcells" \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -F 'stemcell[floating]=false' \
    -F 'stemcell[file]=@/path/to/stemcell/bosh-stemcell-3468.24-vsphere-esxi-ubuntu-trusty-go_agent.tgz' -k
   
```
for example,
```
export TOKEN="xxx"

curl -k https://$OPSMAN_IP/api/v0/stemcells  \
  -X POST \
  -H "Authorization: Bearer $TOKEN"  \
  -F 'stemcell[floating]=false' \
  -F 'stemcell[file]=@/data/tas-main/stemcellbuild/bosh-stemcell-1.651-vsphere-esxi-ubuntu-jammy-go_agent.tgz'

...


{"stemcell":{"file":"bosh-vsphere-esxi-ubuntu-jammy-go_agent-1.651.tgz","name":"bosh-vsphere-esxi-ubuntu-jammy-go_agent","os":"ubuntu-jammy","version":"1.651","hypervisor":"esxi","infrastructure":"vsphere"},"existing":true}
```

check logs from opsmanager vm

```
root@opsmanager-3-0:  tail -f  /var/log/opsmanager/production.log

I, [2025-05-08T01:00:18.261009 #1219]  INFO -- : [5322bb20-65dd-4d5b-b4c8-afbbf12fac32] Started POST "/api/v0/stemcells" for 192.168.0.6 at 2025-05-08 01:00:18 +0000
I, [2025-05-08T01:00:18.263615 #1219]  INFO -- : [5322bb20-65dd-4d5b-b4c8-afbbf12fac32] Processing by Api::V0::StemcellsController#create as */*
I, [2025-05-08T01:00:18.263690 #1219]  INFO -- : [5322bb20-65dd-4d5b-b4c8-afbbf12fac32]   Parameters: {"stemcell"=>{"floating"=>"false", "file"=>{"path"=>"/var/tempest/tmp/0000000019", "original_filename"=>"bosh-vsphere-esxi-ubuntu-jammy-go_agent-1.651.tgz"}}}
I, [2025-05-08T01:00:18.342992 #1219]  INFO -- : [5322bb20-65dd-4d5b-b4c8-afbbf12fac32] Valid UAA token
I, [2025-05-08T01:01:36.970148 #1219]  INFO -- : [5322bb20-65dd-4d5b-b4c8-afbbf12fac32] Completed 200 OK in 78706ms (Views: 1.2ms | ActiveRecord: 1.4ms | Allocations: 329043)

```
and upload status from opsmanager vm.
```
root@opsmanager-3-0: ls -alh /var/tempest/tmp
total 1.2G
drwx------  2 tempest-web root        4.0K May  8 01:11 .
drwxr-xr-x 11 tempest-web tempest-web 4.0K Feb 18 08:26 ..
-rw-------  1 tempest-web tempest-web 1.2G May  8 01:11 0000000019
```


# Reference
- https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-operations-manager/3-0/tanzu-ops-manager/install-ops-man-api.html
- https://LOCAL_OPSMAN/docs
- https://developer.broadcom.com/xapis/tanzu-operations-manager-api/3.0//api/v0/stemcells/post/index?scrollString=stemcell  => wrong contents.

