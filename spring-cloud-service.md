```
cf create-service p.config-server standard config-server -c '{"git": { "uri":"https://github.com/myminseok/cook-config", "periodic": true, "refreshRate": 10}}'
```

https://github.com/spring-cloud-services-samples/cook
