
https://bosh.io/docs/runtime-config
https://github.com/cloudfoundry/os-conf-release

https://github.com/myminseok/pivotal-docs/blob/master/bosh-add-on.md?fbclid=IwAR2yLXdmX8qm2ulrbGQUjo2J40SS9YKMqk0KWmpIrn23b5a2Xz25b99GgbY

```
releases:
 - name: os-conf
   version: 20.0.0

addons:
  - name: os-configuration
    jobs:
    - name: pre-start-script
      release: os-conf
      properties:
        script: |-
          #!/bin/bash
          ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
   # include:
   #   deployments:
   #   - xxxx

```

