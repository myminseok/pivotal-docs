# Access Apps-manager via Ssh Turnneling
- assume that `Dev PC` have to use `VPN` to connect to the data center. and no direct access to TAS network.

```
                          <-----        VPN  to Data center    ------->
|------------- Dev PC --------------------|============= jumpbox =================|------------ TAS apps-manager ------------|
 
 
1) add alias localhost

2) edit /etc/hosts

3) establish VPN

4) establish ssh tunneling
ssh -L 127.0.0.2:443:localhost:8443 ubuntu@jumpbox-IP


                                               5) nginx proxy to apps manager( nginx stream) 
					          forward 8443 -> apps manager
                                               

6) access apps manager on webbrowser
https://apps.sys.data.kr

```



### 1. (Dev PC, as root) add alias localhost
this is not to break other system
```
$ ifconfig lo0 alias 127.0.0.2

$ ifconfig lo0
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=1203<RXCSUM,TXCSUM,TXSTATUS,SW_TIMESTAMP>
	inet 127.0.0.1 netmask 0xff000000
	inet6 ::1 prefixlen 128
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
	inet 127.0.0.2 netmask 0xff000000
	nd6 options=201<PERFORMNUD,DAD
	
$ ping 127.0.0.2
	
```	

for reboot

```
sudo crontab -e
@reboot ifconfig lo0 alias 127.0.0.2
```

### 2. (Dev PC)  Establish VPN to Datacenter

### 3. (Dev PC, as root) etc/hosts
```
127.0.0.2	apps.sys.data.kr
127.0.0.2	login.sys.data.kr
127.0.0.2	uaa.sys.data.kr
127.0.0.2	apps.sys.data.kr
```

### 4. (Dev PC, as root)
you have to open port 443 on localhost, use root for permission. ( apps manager forward the url port to 443 on webbrowser)
```
ssh -L 127.0.0.2:443:localhost:8443 ubuntu@jumpbox-IP
```

### 5. (Jumpbox, as root) setup nginx stream proxy
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
         server 172.16.25.106:443;  # <========== HA proxy or gorouter IP
    }
    server {
       listen 8443 ;
       proxy_pass tas-gorouter-ip;
    }
}
```

- (Jumpbox, as root )  start nginx
```
/usr/sbin/nginx
```

### 6. Access apps manager on webbrowser 
https://apps.sys.data.kr
