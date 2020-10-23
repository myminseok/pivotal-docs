- install guide: https://docs.pivotal.io/spring-cloud-gateway/1-0/installing.html
- gateway domain naming: https://docs.pivotal.io/spring-cloud-gateway/1-0/managing-service-instances.html
- gateway HA:  https://docs.pivotal.io/spring-cloud-gateway/1-0/managing-service-instances.html#high-availability
- CORS: https://docs.pivotal.io/spring-cloud-gateway/1-0/managing-service-instances.html

```
cf create-service p.gateway standard my-gateway -c '{ "host": "myhostname", "domain": "example.com" }'
cf bind-service cook my-gateway -c '{ "routes": [ { "path": "/cook/**" , "filters": [ "StripPrefix=1" ] } ] }'
```
