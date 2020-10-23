Ops manager API를 통해 PAS diego_cell에 추가 network interface card를 추가하는 방법을 설명합니다. 
- https://docs.pivotal.io/pivotalcf/2-6/opsman-api/#configuring-resources-for-a-job

### login to Ops Manager uaa
[opsman_login_uaac](opsman_login_uaac.md)


### director network guid 조회
```
opsman$  uaac -k curl https://<opsman.domain.url>/api/v0/staged/director/networks
{
  "networks": [
    {
      "guid": "0cf837cde7393f37f321",
      "name": "infra-network",
      "subnets": [
        {
          "guid": "8406754cfe91263add85",
          ...
          
        }
      ]
    },
    {
      "guid": "441d7565638fe99478ce",
      "name": "deployment-network",
      "subnets": [
        {
          "guid": "e74288d7818493262c37",
          "iaas_identifier": "VM Network",
          "cidr": "10.10.12.0/24",
          "dns": "10.10.10.5",
          "gateway": "10.10.12.1",
          "reserved_ip_ranges": "10.10.12.1-10.10.12.20",
          "availability_zone_names": [
            "az1",
            "az2"
          ]
        }
      ]
    },
    {
      "guid": "b8109908cccd6f628cdf",
      "name": "ondemand-network",
      "subnets": [
        {
          "guid": "53f74a9a61bc38101da1",
          "iaas_identifier": "VM Network",
          "cidr": "10.10.14.0/24",
          "dns": "10.10.10.5",
          "gateway": "10.10.14.1",
          "reserved_ip_ranges": "10.10.14.1-10.10.14.30",
          "availability_zone_names": [
            "az1",
            "az2"
          ]
        }
      ]
    }
  ]
}

```

### diego_cell vm  resource_config 조회
```
opsman$  uaac -k curl https://<opsman.domain.url>/api/v0/staged/products

{
    "installation_name": "cf-7b6a32f059ba9157bb8f",
    "guid": "cf-7b6a32f059ba9157bb8f",
    "type": "cf",
    "product_version": "2.6.3",
    "label": "Pivotal Application Service",
    "service_broker": false
},
==> product guid 추출


opsman$  uaac -k curl https://<opsman.domain.url>/api/v0/staged/products/<product guid>/jobs
opsman$  uaac -k curl https://<opsman.domain.url>/api/v0/staged/products/cf-7b6a32f059ba9157bb8f/jobs/

  {
      "name": "diego_cell",
      "guid": "diego_cell-0bbd3e7931b651cfc62c"
  },
==> jobs guid 


opsman$  uaac -k curl https://<opsman.domain.url>/api/v0/staged/products/<product guid>/jobs/<jobs guid>/resource_config
opsman$  uaac -k curl https://<opsman.domain.url>/api/v0/staged/products/cf-7b6a32f059ba9157bb8f/jobs/diego_cell-0bbd3e7931b651cfc62c/resource_config

RESPONSE BODY:
{
  "instance_type": {
    "id": "large.disk"
  },
  "instances": 4,
  "additional_networks": [
  ],
  "nsx_security_groups": null,
  "nsx_lbs": [
  ],
  "additional_vm_extensions": [
  ],
  "swap_as_percent_of_memory_size": "automatic"
}
```

### diego_cell vm에 additional network추가
여기서부터는 `uaac curl`이 아닌 `curl`을 사용해야 함. 
```
opsman$  uaac context
[1]*[https://<opsman.domain.url>/uaa]
  skip_ssl_validation: true

  [0]*[admin]
      user_id: 
      client_id: opsman
      access_token: xxxxx.....
      token_type: bearer
      expires_in: 43199
      scope: opsman.admin scim.me uaa.admin clients.admin
      jti: 

$ export TOKEN="<uaac context의 결과에서 access_token을 붙여넣음>"

## additional_networks 항목에 network guid를 추가함.
opsman$  curl -k https://<opsman.domain.url>/api/v0/staged/products/cf-7b6a32f059ba9157bb8f/jobs/diego_cell-0bbd3e7931b651cfc62c/resource_config \
-H "Authorization: bearer $TOKEN" \
-X PUT \
-H "Content-type: application/json" \
-d '{
  "instance_type": {
    "id": "large.disk"
  },
  "instances": 4,
  "additional_networks": [{
      "guid": "b8109908cccd6f628cdf"
   }],
  "nsx_security_groups": null,
  "nsx_lbs": [
  ],
  "additional_vm_extensions": [
  ],
  "swap_as_percent_of_memory_size": "automatic"
}' -k -vv



HTTP/1.1 200 OK
{}


```
### diego_cell vm  resource_config 조회
```
opsman$  uaac -k curl https://<opsman.domain.url>/api/v0/staged/products/<product guid>/jobs/<jobs guid>/resource_config
RESPONSE BODY:
{
  "instance_type": {
    "id": "large.disk"
  },
  "instances": 4,
  "additional_networks": [
    {"guid": "b8109908cccd6f628cdf"},
    {"guid": "xxxx"}
   ],
  "nsx_security_groups": null,
  "nsx_lbs": [
  ],
  "additional_vm_extensions": [
  ],
  "swap_as_percent_of_memory_size": "automatic"
}

```
### 'apply change' in opsmanager
now, next 'apply change'  will add a new nic to your CELL vms.
```
===== 2019-10-15 04:38:44 UTC Running "/usr/local/bin/bosh --no-color --non-interactive --tty --environment=10.10.10.21 --deployment=cf-7b6a32f059ba9157bb8f deploy /var/tempest/workspaces/default/deployments/cf-7b6a32f059ba9157bb8f.yml"
Using environment '10.10.10.21' as client 'ops_manager'

Using deployment 'cf-7b6a32f059ba9157bb8f'

 instance_groups:
 - name: diego_cell
   networks:
   - name: PAS-network
     default:
      - dns
      - gateway
  - name: DB-network

Task 498045
```

Cell vm has an additional NIC.
```
Deployment 'cf-7b6a32f059ba9157bb8f'

Instance                                                            Process State  AZ   IPs           VM CID                                   VM Type      Active
backup_restore/d26ce9ca-0c46-41b0-b211-053939eed9fc                 running        az1  10.10.12.25   vm-4242f172-cef8-4939-bb48-31efe4c87feb  micro        true
clock_global/2bfe6bc2-26b4-49dd-90d6-9c8aefdc27fc                   running        az1  10.10.12.32   vm-afb2ba2b-0a63-4ee0-857c-2dc692ce6370  medium.disk  true
cloud_controller/6ceebbc2-19a2-40d5-8ce1-7250d10793b6               running        az1  10.10.12.28   vm-f302b49f-3b41-47bc-913a-81ec345ce93c  medium.disk  true
cloud_controller_worker/a1bcd628-300e-4996-b3a3-c665a8ec8834        running        az1  10.10.12.33   vm-8147b18a-320d-4924-8902-7b6005beb9b8  micro        true
credhub/268c88a4-f515-4748-b25a-8addf5c9c209                        running        az1  10.10.12.45   vm-3b2b624e-6eb8-49c7-ab47-6e0e96ce7136  large        true
diego_brain/62124476-f15f-4c76-b8ac-e5caf1ae76a7                    running        az1  10.10.12.29   vm-ba3734af-200e-4ee5-9d58-fb9f532a2b3d  small        true
diego_cell/4e401ed9-e6d3-4c1a-87fc-838d37a70747                     running        az1  10.10.12.34   vm-c914d5c0-a36b-424d-ab8c-88baab67e5de  large.disk   true
                                                                                        10.10.14.41
diego_cell/5542bdbc-4f54-4d1b-8d43-c2075a2d123d                     running        az2  10.10.12.38   vm-572f459d-81ca-49b6-8c93-448dc9e8e6ee  large.disk   true
                                                                                        10.10.14.43
diego_cell/718a3bd2-d5ee-4898-9694-7c822057352f                     running        az2  10.10.12.40   vm-23e5f33a-271b-4bfe-a610-c5d95a2d62d0  large.disk   true
                                                                                        10.10.14.44
diego_cell/84fc48e7-52d7-42ee-8306-da176fc2e571                     running        az1  10.10.12.36   vm-7ba60bfd-3504-45d3-869f-2803a2212cd0  large.disk   true
  



instance_groups:
- name: isolated_diego_cell_x
  networks:
  - name: NET-DB                                                                                      10.10.14.42
                                                                                   
```


#troubleshooting
Error: Instance group isolated_diego_cell_x must specify availability zone that matches availability zone if network NET-DB

NET-IS1 
- AZ-IS1

NET-DB
- AZ-IS1

