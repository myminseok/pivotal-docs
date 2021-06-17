# Access  TAS Apps-manager via Ssh Tunneling
There is some private(airgapped) environment where the ssh is the only way to access. it means that `Dev PC` has no direct access to TAS network. and if there is some apps on target environment where you have to use web-brower, then simply you have to provide windows jumpbox or desktop jumpbox with web-brower included. it can be simple but if there are lots of students then it consumes cloud resource and time to setup. This doc explans how to enable accessing the target app with a single ubuntu jumpbox. students can simply use local web brower to the target web app.

```
                          <-----       ssh tunneling  to Data center    ------->
|------------- Student PC --------------------|============= jumpbox(ubuntu) =================|------------ TAS ------------|
 
 
1) add alias localhost

2) edit /etc/hosts

3) establish VPN (if required)

4) establish ssh tunneling
ssh -L 127.0.0.2:443:localhost:8443 ubuntu@jumpbox-IP


                                               5) nginx stream
					          forward 8443 -> apps manager:443

6) access apps manager on webbrowser
https://apps.sys.data.kr   ---> 127.0.0.2:443 ---(ssh tunnel)---> ubnutu-jumpbox:8443 ---> nginx stream:8443 ---(forward to)-- TAS gorouter:443  

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

### 2. (Dev PC)  

#### Mac
- Establish VPN to Datacenter (if required)
-  vi etc/hosts
```
127.0.0.2	apps.sys.data.kr
127.0.0.2	login.sys.data.kr
127.0.0.2	uaa.sys.data.kr
```
- port forwarding: then you have to open port 443 on localhost, use root for permission. ( apps manager forward the url port to 443 on webbrowser)
```
ssh -L 127.0.0.2:443:localhost:8443 ubuntu@jumpbox-IP
```

#### windows
- Establish VPN to Datacenter (if required)
- host setting as administrator
```
C:\Windows\System32\drivers\etc\host

127.0.0.2	apps.sys.data.kr
127.0.0.2	login.sys.data.kr
127.0.0.2	uaa.sys.data.kr
```
- port forwarding
```
netsh interface portproxy add v4tov4 listenport=443 listenaddress=127.0.0.2 connectport=8443 connectaddress=jumpbox-IP
netsh interface portproxy show v4tov4
## to delete
netsh interface portproxy delete v4tov4 listenport=443 listenaddress=127.0.0.1
```


### 3. (Jumpbox, as root) setup nginx stream proxy
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
