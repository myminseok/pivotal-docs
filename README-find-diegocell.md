```
cf login -a api.system.pcfdemo.net --skip-ssl-validation


cf curl /v2/apps/$(cf app env  --guid)/stats | jq .
{
  "0": {
    "state": "RUNNING",
    "stats": {
      "name": "env",
      "uris": [
        "env.apps.lab.pcfdemo.net"
      ],
      "host": "192.168.0.91",
      "port": 40000,
      "uptime": 2355,
      "fds_quota": 16384,
      "mem_quota": 536870912,
      "disk_quota": 1073741824,
      "log_rate_limit": 16384,
      "usage": {
        "time": "2025-04-02T01:08:54+00:00",
        "cpu": 0.01250097299239791,
        "cpu_entitlement": 0.08533476687731598,
        "mem": 177246208,
        "disk": 80585728,
        "log_rate": 0
      }
    },
    "routable": true,
    "isolation_segment": "win"
  }
}


```

```
cf oauth-token

export TOKEN=""

curl -L -H "Authorization: Bearer $TOKEN"  https://CF-API

```



