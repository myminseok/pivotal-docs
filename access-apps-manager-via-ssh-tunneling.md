# Access Apps-manager via Ssh Turnneling
- assume that `Dev PC` have to use `VPN` to connect to the data center. and no direct access to TAS network.

```
                          <-----        VPN  to Data center    ------->
|------------- Dev PC --------------------|============= jumpbox =================|------------ TAS apps-manager ------------|
 
0) establish VPN

1) /etc/hosts
127.0.0.1	apps.sys.data.kr
127.0.0.1	login.sys.data.kr
127.0.0.1	uaa.sys.data.kr
127.0.0.1	apps.sys.data.kr


2) as root
ssh -L 443:localhost:8443 ubuntu@jumpbox


                                               3) nginx proxy to apps manager( nginx stream) 
                                               

4) on webbrowser
https://apps.sys.data.kr

```

### 0. (Dev PC)  Establish VPN to Datacenter

### 1. (Dev PC) etc/hosts
```
127.0.0.1	apps.sys.data.kr
127.0.0.1	login.sys.data.kr
127.0.0.1	uaa.sys.data.kr
127.0.0.1	apps.sys.data.kr
```

### 2. (Dev PC) as root
you have to open port 443 on localhost, use root for permission. ( apps manager forward the url port to 443 on webbrowser)
```
ssh -L 443:localhost:8443 ubuntu@jumpbox-IP
```

### 3. (Jumpbox) setup nginx stream proxy
- check connectivity to apps manager
```
nc -zv aps.sys.data.kr 443
Connection to aps.sys.data.kr 443 port [tcp/https] succeeded!

ubuntu@192:~$ curl -k https://apps.sys.data.kr -H "host: apps.sys.data.kr"
<!DOCTYPE html>
<html lang="en">
<head>
    <title> Apps Manager</title>
....

```

- compile nginx with stream and make install: reference to https://github.com/myminseok/nginx-stream
- edit nginx.conf
```
root@192:/home/ubuntu# cat /etc/nginx/nginx.conf
user www-data;
worker_processes 1;
pid /run/nginx.pid;

events {
	worker_connections 768;
}


stream {
    upstream tas-gorouter-ip {
         server 172.16.25.106:443;  # <========== HA proxy or gorouter IP.
    }
    server {
       listen 8443 ;
       proxy_pass tas-gorouter-ip;
    }
}
```

- (jumpbox )  start nginx  (as root)
```
/usr/sbin/nginx
```

### 4. Access apps manager
on webbrowser https://apps.sys.data.kr
