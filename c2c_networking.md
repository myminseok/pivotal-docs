


## container to container networking in the same space:
- https://docs.pivotal.io/pivotalcf/2-4/devguide/deploy-apps/cf-networking.html


## container to container networking between different org or space:
- https://github.com/cloudfoundry/cf-networking-release/blob/develop/docs/API_v0.md


### prepare apps in different org/space
```

$ cf domains
name                    status   type   details
apps.pcfdemo.net        shared
apps.internal           shared          internal


$ cf target -o BACKEND -s dev

$ cf app backend-app --guid
backend-app-guid



$ cf map-route backend-b apps.internal --hostname backend



$ cf 

$ cf target -o ORG2 -s dev
$ cf app spring-music-org2 --guid
spring-music-org2-guid


```
