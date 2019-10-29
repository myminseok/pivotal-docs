Ops manager API를 통해 PAS diego_cell에 추가 network interface card를 추가하는 방법을 설명합니다. 
- https://docs.pivotal.io/pivotalcf/2-6/opsman-api/#configuring-resources-for-a-job

### Ops Manager VM에 ssh 접속하기
```
chmod 600 <opsmanager_ssh.keyfile>
ssh -i <opsmanager_ssh.keyfile> ubuntu@<opsman.url>
```

### uaac login
```
opsman$ uaac target https://<opsman.domain.url>/uaa --skip-ssl-validation
Target: https://<opsman.domain.url>/uaa
Context: admin, from client opsman

opsman$  uaac token owner get
Client ID:  opsman
Client secret:
User name:  admin
Password:  <opsman ui admin password>

Successfully fetched token via owner password grant.
Context: admin, from client opsman

```

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
  "additional_networks": [{
      "guid": "b8109908cccd6f628cdf"
   }],
  "nsx_security_groups": null,
  "nsx_lbs": [
  ],
  "additional_vm_extensions": [
  ],
  "swap_as_percent_of_memory_size": "automatic"
}

```
### 'apply change' in opsmanager
```
opsman$ bosh vms

```


