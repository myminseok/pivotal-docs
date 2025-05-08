## Uploading a product via opsmanager API

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


```

2. upload a product

during the api call, there is no output until it uploads completely. check logs from opsman vm under /var/log/opsmanager/production.log

```
curl "https://example.com/api/v0/available_products" \
    -X POST \
    -H "Authorization: Bearer UAA_ACCESS_TOKEN" \
    -F 'product[file]=@/path/to/component.zip'
```
for example,
```
export TOKEN="xxx"

curl  https://192.168.0.50/api/v0/available_products  \
  -X POST \
  -H "Authorization: Bearer $TOKEN"  \
  -F 'product[file]=@/Users/kminseok/Downloads/_files/TAS6/postgres-1.2.2-build.1.pivotal' -k

...

{}%
```

check logs from opsmanager vm

```
root@opsmanager-3-0:  tail -f  /var/log/opsmanager/production.log
...
I, [2025-05-08T02:10:11.139450 #1199]  INFO -- : [4bc9ee42-6683-4a73-b55c-510307eaf624] Started POST "/api/v0/available_products" for 192.168.0.250 at 2025-05-08 02:10:11 +0000
I, [2025-05-08T02:10:11.142088 #1199]  INFO -- : [4bc9ee42-6683-4a73-b55c-510307eaf624] Processing by Api::V0::AvailableProductsController#create as */*
I, [2025-05-08T02:10:11.142205 #1199]  INFO -- : [4bc9ee42-6683-4a73-b55c-510307eaf624]   Parameters: {"product"=>{"file"=>{"path"=>"/var/tempest/tmp/0000000004", "original_filename"=>"postgres-1.2.2-build.1.pivotal"}}}
I, [2025-05-08T02:10:11.265515 #1199]  INFO -- : [4bc9ee42-6683-4a73-b55c-510307eaf624] Valid UAA token
...

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
- https://LOCAL_OPSMAN/docs



