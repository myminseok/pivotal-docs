# access apps manager via ssh turnneling

```
|------------- dev PC --------------------|============= jumpbox =================|------------ TAS apps-manager ------------|
 
1) /etc/hosts
127.0.0.1	apps.sys.data.kr
127.0.0.1	login.sys.data.kr
127.0.0.1	uaa.sys.data.kr
127.0.0.1	apps.sys.data.kr


2) as root
ssh -L 443:localhost:8443 ubuntu@jumpbox


                                               3) nginx proxy to apps manager( nginx stream) 
                                               

4) 

in webbrowser
https://apps.sys.data.kr

```
### 1. (dev PC) etc/hosts
```
127.0.0.1	apps.sys.data.kr
127.0.0.1	login.sys.data.kr
127.0.0.1	uaa.sys.data.kr
127.0.0.1	apps.sys.data.kr
```

### 2. as root
you have to open port 443 on localhost, use root for permission. ( apps manager forward the url port to 443 on webbrowser)
```
ssh -L 443:localhost:8443 ubuntu@jumpbox-IP
```

### 3. (jumpbox) nginx proxy
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

- start nginx  (as root)
```
/usr/sbin/nginx
```
