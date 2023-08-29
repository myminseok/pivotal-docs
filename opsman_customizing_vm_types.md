referes to https://docs.pivotal.io/platform/2-10/opsman-api/#tag/VM-types/paths/~1api~1v0~1vm_types/put

### login to Ops Manager uaa
[opsman_login_uaac](opsman_login_uaac.md)


### export uaac access token

```
$ uaac contexts

## copy access token and export to 

$ export UAA_ACCESS_TOKEN=

```

### customize vm_types in opsman
#### extract vm_types
```

$ curl -k "https://localhost/api/v0/vm_types" \
    -X GET \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN" | jq . > vm_types.txt
   
   
  ===> 
    {
  "vm_types": [
    {
      "name": "nano",
      "ram": 512,
      "cpu": 1,
      "ephemeral_disk": 1024,
      "builtin": true
    },
    ...
    ]
    }
  ```

#### customize the results and apply to opsman.

```

curl -k "https://localhost/api/v0/vm_types" \
    -X PUT \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
          "vm_types": [
            {
              "name": "nano",
              "ram": 512,
              "cpu": 1,
              "ephemeral_disk": 1024,
              "builtin": true
            },
            {
              "name": "bigger",
              "cpu": 2,
              "ram": 2048,
              "ephemeral_disk": 2048
            }
          ]
        }'
  
  ## using file.
  
  
  curl -k "https://localhost/api/v0/vm_types" \
    -X PUT \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    --data-binary @vm_types.txt
  
```

### using om cli
```
 om -e env.yml curl -p /api/v0/vm_types
 om -e env.yml curl -p /api/v0/vm_types -x PUT -d @vm_types.txt
```

now there is a new 'bigger' vm types in opsma UI.
    
