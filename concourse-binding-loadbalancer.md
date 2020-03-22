
## binding a loadbalancer on concourse web
you can bind web VM to load-balancer automatically using vm_extensions setting in bosh cloud-config which has different configuration per IAAS. ex)  https://bosh.io/docs/aws-cpi/#resource-pools

## Prerequisites.
- [Setting up concourse](concourse-with-credhub.md)


#### prepare external loadbalancer (elb)
```
- name: concourse-lb
- HTTP 80
- HTTPS 443
- TCP 8443 
- TCP 8844
```

#### set `vm extension` for concourse web loadbalancer.

##### case) set `vm extension` for OSS bosh
- define in cloud-config: https://bosh.io/docs/cloud-config/#vm-extensions
- and use it from manifest in `instance_groups` : https://bosh.io/docs/manifest-v2/

```
$ bosh cloud-config > bosh-cloud-config.yml

$ vi bosh-cloud-config.yml
vm_extensions:
- cloud_properties:
    elbs: "[concourse-lb]"
  name: lb
  
$ bosh update-cloud-config ./bosh-cloud-config.yml
```

##### case) set `vm extension` using ops-manager

https://docs.pivotal.io/pivotalcf/2-6/customizing/custom-vm-extensions.html
```

curl -vv -k "https://localhost/api/v0/staged/vm_extensions" \
    -X POST \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name": "lb", "cloud_properties": { "elbs": "[concourse-lb]" }}'

=> apply change

curl -k "https://localhost/api/v0/deployed/vm_extensions" \
    -X GET \
    -H "Authorization: Bearer $UAA_ACCESS_TOKEN"

```


#### deploy concourse with the load-balancer 

```
bosh deploy -n --no-redact -d concourse concourse.yml \
 ...
  -o operations/web-network-extension.yml \
  ...
  --var web_network_vm_extension=lb \
```
