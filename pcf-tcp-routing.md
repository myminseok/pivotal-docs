
## Enable TCP routing in PAS tile 
https://docs.pivotal.io/pivotalcf/2-5/adminguide/enabling-tcp-routing.html
```
port range: 1024-65535
```
apply change

## Set DNS
ROUTER_LB_IP tcp.apps.pcfdemo.net

## Create tcp domain

```
$ cf router-groups
name          type
default-tcp   tcp

$ cf create-shared-domain tcp.APPS-DOMAIN.com --router-group default-tcp

$ cf domains
name                    status   type   details
apps.pcfdemo.net        shared
apps.internal           shared          internal
tcp.apps.pcfdemo.net    shared   tcp
```


## Set quota for route port
```
cf update-quota default --reserved-route-ports 100

cf quotas
name      total memory   instance memory   routes   service instances   paid plans   app instances   route ports
default   10G            unlimited         1000     1000                allowed      unlimited       100
runaway   100G           unlimited         1000     unlimited           allowed      unlimited       0

```

## Push sample app
```
$ git clone https://github.com/cloudfoundry-samples/capi-sidecar-samples.git

$ ./push_java_app_with_binary_sidecar.sh

$ cf apps
name                         requested state   instances   memory   disk   urls
sidecar-dependent-java-app   started           1/1         1G       1G     sidecar-dependent-java-app.apps.pcfdemo.net


$ curl sidecar-dependent-java-app.apps.pcfdemo.net
Hello I am a sidecar-dependent java app.  Visit <a href="/config">the config endpoint</a> to see me retrieve a value from my sidecar

$ curl sidecar-dependent-java-app.apps.pcfdemo.net/config
{"Scope":"some-service.admin","Password":"not-a-real-p4$$w0rd"}


$ cf ssh sidecar-dependent-java-app

vcap@18822d0f-418f-4e04-78b1-2df6:~$ netstat -nlp
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:61001           0.0.0.0:*               LISTEN      -
tcp        0      0 0.0.0.0:61002           0.0.0.0:*               LISTEN      -
tcp        0      0 0.0.0.0:61003           0.0.0.0:*               LISTEN      -
tcp        0      0 127.0.0.1:61004         0.0.0.0:*               LISTEN      -
tcp        0      0 0.0.0.0:2222            0.0.0.0:*               LISTEN      62/diego-sshd
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      13/java
tcp        0      0 0.0.0.0:8082            0.0.0.0:*               LISTEN      25/./config-server-


```


## Map-routes (from tcp port to container port 8080)
https://docs.pivotal.io/pivotalcf/2-5/devguide/deploy-apps/routes-domains.html
```
$ cf routes
space   host                         domain             port   path   type   apps                         service
dev     sidecar-dependent-java-app   apps.pcfdemo.net                        sidecar-dependent-java-app

$ cf map-route sidecar-dependent-java-app tcp.apps.pcfdemo.net --port 8082

$ cf routes
space   host                         domain                 port   path   type   apps                         service
dev     sidecar-dependent-java-app   apps.pcfdemo.net                            sidecar-dependent-java-app
dev                                  tcp.apps.pcfdemo.net   8082          tcp    sidecar-dependent-java-app

$ cf apps
name                         requested state   instances   memory   disk   urls
sidecar-dependent-java-app   started           1/1         1G       1G     sidecar-dependent-java-app.apps.pcfdemo.net, tcp.apps.pcfdemo.net:8082

$ curl sidecar-dependent-java-app.apps.pcfdemo.net
Hello I am a sidecar-dependent java app.  Visit <a href="/config">the config endpoint</a> to see me retrieve a value from my sidecar

$ curl sidecar-dependent-java-app.apps.pcfdemo.net/config
{"Scope":"some-service.admin","Password":"not-a-real-p4$$w0rd"}


$ curl tcp.apps.pcfdemo.net:8082
Hello I am a sidecar-dependent java app.  Visit <a href="/config">the config endpoint</a> to see me retrieve a value from my sidecar

$ curl tcp.apps.pcfdemo.net:8082/config
{"Scope":"some-service.admin","Password":"not-a-real-p4$$w0rd"}

```


## Map routes to container port (other than 8080)
https://docs.pivotal.io/pivotalcf/2-5/devguide/custom-ports.html
```
$ cf app sidecar-dependent-java-app --guid
71117a5a-837e-4331-af04-4f2482d4c2ef

$ cf curl /v2/apps/71117a5a-837e-4331-af04-4f2482d4c2ef -X PUT -d '{"ports":[8080,8082]}'

$ cf curl /v2/routes?q=port:8082
{
   "resources": [
      {
         "metadata": {
            "guid": "39200a51-694e-42e3-a46c-0d5d794bca55",
            "url": "/v2/routes/39200a51-694e-42e3-a46c-0d5d794bca55",

$ cf curl /v2/route_mappings  -X POST -d '{"app_guid":"71117a5a-837e-4331-af04-4f2482d4c2ef ", "route_guid":"39200a51-694e-42e3-a46c-0d5d794bca55", "app_port":8082}'


wait few seconds for setting.

$ curl sidecar-dependent-java-app.apps.pcfdemo.net
Hello I am a sidecar-dependent java app.  Visit <a href="/config">the config endpoint</a> to see me retrieve a value from my sidecar

$ curl sidecar-dependent-java-app.apps.pcfdemo.net/config
{"Scope":"some-service.admin","Password":"not-a-real-p4$$w0rd"}

$ curl tcp.apps.pcfdemo.net:8082
404 page not found

$ curl tcp.apps.pcfdemo.net:8082/config
{"Scope":"some-service.admin","Password":"not-a-real-p4$$w0rd"}
```




