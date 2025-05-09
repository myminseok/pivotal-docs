1. ssh into opsman vm and sudo -i

2. vi /etc/tempest.d/tempest-web

```
#!/bin/bash
# shellcheck disable=SC1090
source "$(cd "$(dirname "${0}")" && pwd)/common-env"
exec >> "${LOG_DIR}/tempest-web.log" 2>&1

## === START for debugging ===
export BOSH_LOG_LEVEL=DEBUG
export BOSH_LOG_PATH=/tmp/bosh_init.debug
export EXCON_DEBUG="true"
## === END for debugging ===

export RAILS_ENV=production
...
```
3. 
```
service tempest-web restart

service tempest-web stop && service tempest-web start 

service nginx restart
```

4. apply change in opsman UI 

5. tail -f /tmp/bosh_init.debug in opsman VM.

