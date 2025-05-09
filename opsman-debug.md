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


## old

https://community.pivotal.io/s/article/Enabling-Bosh-init-Debug-Logs-in-the-Ops-Manager

```
/home/tempest-web/tempest/web/app/models/deployer/executors/bosh_executors.rb


1. SSH to Ops Manager VM
2. pkill -f bosh-init
3. find /home/tempest-web | grep bosh_init_cli_executor.rb
4. Prepend BOSH_INIT_LOG_LEVEL=debug in front of the line "bosh-init #{command} #{manifest_file_path} > /tmp/bosh-init.log"
5. Run service tempest-web stop && service tempest-web start && service nginx restart
```
Apply Changes and you should see a more detailed output in the log. 

  



