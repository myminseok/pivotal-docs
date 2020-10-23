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

$ curl "https://example.com/api/v0/vm_types" \
    -X GET \
    -H "Authorization: Bearer UAA_ACCESS_TOKEN"
   
   
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
curl "https://example.com/api/v0/vm_types" \
    -X PUT \
    -H "Authorization: Bearer UAA_ACCESS_TOKEN" \
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
  
```

now there is a new 'bigger' vm types in opsma UI.
    
