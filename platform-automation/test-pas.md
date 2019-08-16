

### login to apps manager UI
- https://docs.pivotal.io/pivotalcf/2-6/customizing/console-login.html
- admin credentials: Ops man UI>  PAS Credentials > UAA > Admin Credentials.
- create a your org/space

### push sample app
#### install cf cli
- https://docs.pivotal.io/pivotalcf/2-6/cf-cli/install-go-cli.html
- admin credentials: Ops man UI>  PAS Credentials > UAA > Admin Credentials.
```

cf login -a api.<YOUR-PCF-SYS-DOMAIN> --skip-ssl-validation

```
#### cf push
```
git clone https://github.com/myminseok/spring-music
cd spring-music


cat manifest.yml
---
applications:
- name: spring-music
  memory: 1G
  buildpacks: 
  - java_buildpack_offline
  random-route: true
  #path: build/libs/spring-music.jar
  path: ./spring-music.jar


cf push
```


#### troubleshooting
https://github.com/myminseok/pivotal-docs/blob/master/ssh-login-opsman-bosh.md

