


## Container to container networking using cf network-policy:
- https://docs.pivotal.io/pivotalcf/2-4/devguide/deploy-apps/cf-networking.html

```
$ cf target -o BACKEND-ORG -s dev


$ cf apps
name           requested state   instances   memory   disk   urls
frontend   started           1/1         1G       1G     frontend.apps.pcfdemo.net, frontend.app.internal
backend   started           1/1         1G       1G     backend.app.internal


## cf add-network-policy SOURCE_APP --destination-app DESTINATION_APP --protocol (tcp | udp) --port RANGE

$ cf add-network-policy frontend --destination-app backend --protocol tcp --port 8080 (-s backend-space -o backend-org)

$ cf ssh  frontend
vcap@xxxxx $ curl -k http://backend.apps.local:8080/



```


## Container to container networking using `cf curl`:
- https://github.com/cloudfoundry/cf-networking-release/blob/develop/docs/API_v0.md


### prepare apps in different org/space
```

$ cf domains
name                    status   type   details
apps.pcfdemo.net        shared
apps.internal           shared          internal


$ cf target -o BACKEND-ORG -s dev

$ cf map-route backend-app apps.internal --hostname backend-app

$ cf apps
name           requested state   instances   memory   disk   urls
backend-app   started           1/1         1G       1G     backend-app.apps.internal

```
### set c2c 
```
$ cf app backend-app --guid
backend-app-GUID

$ cf target -o FRONTEND-ORG -s dev
$ cf app frontend-app --guid
frontend-app-GUID


$ vi networking-policies
{
  "policies": [
    {
      "source": {
        "id": "frontend-app-GUID"
      },
      "destination": {
        "id": "backend-app-GUID",
        "protocol": "tcp",
        "port": 8080
      }
    }
   ]
 }

$ cf curl /networking/v0/external/policies -X POST -d ./networking-policies
{}


$ cf curl /networking/v0/external/policies

$ cf ssh  frontend-app
vcap@xxxxx $ curl -k http://backend-app.apps.local:8080/



```
