```
# ssh into opsman vm
sudo -i

vi /etc/tempest.d/tempest-web

export BOSH_LOG_LEVEL=DEBUG
export BOSH_LOG_PATH=/tmp/bosh_init.debug
export EXCON_DEBUG="true"

service tempest-web restart

tail -f /tmp/bosh_init.debug
```
