```
# ssh into opsman vm
sudo -i

vi /etc/tempest.d/tempest-web


## tail -f /var/log/opsmanager/tempest-web.log
export EXCON_DEBUG="true"

export BOSH_LOG_LEVEL=DEBUG
export BOSH_LOG_PATH=/tmp/bosh_init.debug


service tempest-web restart
```

```

tail -f /var/log/opsmanager/tempest-web.log
tail -f /tmp/bosh_init.debug
```
