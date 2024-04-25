
this document explains how to add network route config using os-release runtime-config.

### Upload release
https://bosh.io/releases/github.com/cloudfoundry/os-conf-release?all=1
```
bosh upload-release --sha1 daf34e35f1ac678ba05db3496c4226064b99b3e4 \
  "https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v=22.2.1"
```

### Create runtime-config
osconf-runtimeconfig.yml

```
releases:
- name: os-conf
  version: 22.2.1

addons:
- name: os-configuration
  include:
    deployments:
    - p-isolation-segment-is1-6e18f0c63108927910d4
  jobs:
  - name: pre-start-script
    release: os-conf
    properties:
      script: |-
        #!/bin/bash

        CONFIG_PATH=/etc/systemd/network/10_eth1.network.d/custom-network.conf
        ## https://mmonit.com/monit/documentation/monit.html#EXISTENCE-TESTS
        cat > /var/vcap/jobs/pre-start-script/monit <<EOF
        check file pre-start-script with path $CONFIG_PATH
          if does not exist then exec  "/var/vcap/jobs/post-deploy-script/bin/post-deploy"
          group root
        EOF


  - name: post-deploy-script
    release: os-conf
    properties:
      script: |-
        #!/bin/bash
        #ip route delete 10.0.0.0/8 via 192.168.40.1 dev eth1
        #ip route add 10.0.0.0/8 via 192.168.40.1 dev eth1

        CONFIG_PATH=/etc/systemd/network/10_eth1.network.d/custom-network.conf
        DIR="$(dirname "${CONFIG_PATH}")"
        rm -rf $DIR && mkdir -p $DIR
        
        cat > $CONFIG_PATH <<EOF
        [Route]
        Gateway=192.168.40.1
        Destination=192.1.1.0/24
        GatewayOnLink=yes
        EOF

        systemctl restart systemd-networkd
```
> replace with relevant NIC name to network folder. ex. /etc/systemd/network/10_eth1.network.d

```
bosh update-runtime-config --name=osconf-is ./osconf-runtimeconfig.yml
```

bosh configs
```
ubuntu@opsmanager-3-0:~/workspace$ bosh configs
Using environment '192.168.0.55' as client 'ops_manager'

ID   Type     Name                                      Team  Created At
9*   cloud    default                                   -     2024-04-25 10:31:59 UTC
8*   cpi      default                                   -     2024-03-19 06:48:22 UTC
7*   runtime  cf-e6d5fd0144a750a9b8ca-bosh-dns-aliases  -     2024-03-18 08:56:54 UTC
3*   runtime  director_runtime                          -     2024-03-18 08:14:44 UTC
1*   runtime  ops_manager_dns_runtime                   -     2024-03-18 08:14:44 UTC
2*   runtime  ops_manager_system_metrics_runtime        -     2024-03-18 08:14:44 UTC
29*  runtime  osconf-is                                 -     2024-04-25 15:58:24 UTC

```

### Apply runtime config to deployment
```
bosh -d p-isolation-segment-is1-6e18f0c63108927910d4 deploy iso-manifest.yml
```

then, following artifacts are created in the deployed VM

- /var/vcap/jobs/pre-start-script/bin/pre-start
```
#!/bin/bash

CONFIG_PATH=/etc/systemd/network/10_eth1.network.d/custom-network.conf
cat > /var/vcap/jobs/pre-start-script/monit <<EOF
check file pre-start-script with path $CONFIG_PATH
  if does not exist then exec  "/var/vcap/jobs/post-deploy-script/bin/post-deploy"
  group root
EOF
```

-  /var/vcap/jobs/pre-start-script/monit
```
check file pre-start-script with path /etc/systemd/network/10_eth1.network.d/custom-network.conf
  if does not exist then exec  "/var/vcap/jobs/post-deploy-script/bin/post-deploy"
  group root
```

above  "pre-start-script" monit job will be executed if:
- vm is deployed
- vm is rebooted
- anytime the file is not exists after deployed.


- /var/vcap/monit/job/0001_pre-start-script.monitrc
```
check file pre-start-script with path /etc/systemd/network/10_eth1.network.d/custom-network.conf
  if does not exist then exec  "/var/vcap/jobs/post-deploy-script/bin/post-deploy"
  group root
```


- /var/vcap/jobs/post-deploy-script/bin/bin/post-deploy
```
#!/bin/bash
#ip route delete 10.0.0.0/8 via 192.168.40.1 dev eth1
#ip route add 10.0.0.0/8 via 192.168.40.1 dev eth1

CONFIG_PATH=/etc/systemd/network/10_eth1.network.d/custom-network.conf
DIR="$(dirname "${CONFIG_PATH}")"
rm -rf $DIR && mkdir -p $DIR
cat > $CONFIG_PATH <<EOF
[Route]
Gateway=192.168.40.1
Destination=192.1.1.0/24
GatewayOnLink=yes
EOF

systemctl restart systemd-networkd
```

monit summary

```
Process 'bosh-dns'                  running
Process 'bosh-dns-resolvconf'       running
Process 'bosh-dns-healthcheck'      running
Process 'system-metrics-agent'      running
File 'pre-start-script'             accessible
System 'system_9debe3d9-1bf2-4db5-aea9-a5cda579daf9' running
```


and monit will create following network config.

```
find /etc/systemd/network

/etc/systemd/network
/etc/systemd/network/10_eth0.network
/etc/systemd/network/10_eth1.network.d
/etc/systemd/network/10_eth1.network.d/custom-network.conf
/etc/systemd/network/10_eth1.network

```

/etc/systemd/network/10_eth1.network.d/custom-network.conf
```
[Route]
Gateway=192.168.40.1
Destination=192.1.1.0/24
GatewayOnLink=yes
```

and route config.
```
ip route show

default via 192.168.0.1 dev eth0 proto static
192.1.1.0/24 via 192.168.40.1 dev eth1 proto static onlink
192.168.0.0/24 dev eth0 proto kernel scope link src 192.168.0.76
192.168.40.0/24 dev eth1 proto kernel scope link src 192.168.40.11
```


## ref
- https://bosh.io/docs/runtime-config/
- https://github.com/cloudfoundry/os-conf-release



