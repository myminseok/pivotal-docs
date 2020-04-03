### (offline env) download bind9 dependencies

```
sudo su

apt-get update

apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \ --no-conflicts --no-breaks --no-replaces --no-enhances \ --no-pre-depends bind9 | grep "^\w")



dpkg -i *.deb

apt install -f

```

## setup DNS

```
apt-get install bind9
```

## setup ipv4 for bind9
vi /etc/default/bind9
```
OPTIONS="-4 -u bind"
```

## setup domain

```
sudo su
cd /etc/bind

cp db.local db.pcfdemo.net
pivotal@ubuntu:/etc/bind$ cat db.pcfdemo.net 


;
; BIND data file for local loopback interface
;
$TTL 604800
@ IN SOA pcfdemo.net. root.pcfdemo.net. (
        2; Serial
   604800; Refresh
    86400; Retry
  2419200; Expire
 604800 ); Negative Cache TTL
;
@ IN NS pcfdemo.net.
@ IN A       192.168.0.100
* IN A       192.168.0.100
@ IN AAAA ::1

```


```
pivotal@ubuntu:/etc/bind$ cat db.apps.pcfdemo.net 
;
; BIND data file for local loopback interface
;
$TTL 604800
@ IN SOA apps.pcfdemo.net. root.apps.pcfdemo.net. (
      2; Serial
 604800; Refresh
  86400; Retry
2419200; Expire
 604800 ); Negative Cache TTL
;
@ IN NS apps.pcfdemo.net.
@ IN A       192.168.0.100
* IN A       192.168.0.100
@ IN AAAA::1
```

```
pivotal@ubuntu:/etc/bind$ cat db.system.pcfdemo.net 
;
; BIND data file for local loopback interface
;
$TTL 604800
@ IN SOA system.pcfdemo.net. root.system.pcfdemo.net. (
      2; Serial
 604800; Refresh
  86400; Retry
2419200; Expire
 604800 ); Negative Cache TTL
;
@ IN NS system.pcfdemo.net.
@ IN AAAA::1
@ IN A       192.168.0.100
* IN A       192.168.0.100
login IN A       192.168.0.100
uaa IN A       192.168.0.100
ssh IN A       192.168.0.xxx

```

```
pivotal@ubuntu:/etc/bind$ cat named.conf.local 
//
// Do any local configuration here
//
// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "pcfdemo.net" {
    type master;
    file "/etc/bind/db.pcfdemo.net";
};
zone "apps.pcfdemo.net" {
    type master;
    file "/etc/bind/db.apps.pcfdemo.net";
};
zone "system.pcfdemo.net" {
    type master;
    file "/etc/bind/db.system.pcfdemo.net";
};

```

#forward설정

vi /etc/bind/named.conf.options
```
root@oss-jumpbox:/etc/bind# cat named.conf.options 
options {
	directory "/var/cache/bind";


        // forwarder... https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-14-04
        recursion yes; 
	//dnssec-validation auto;
        dnssec-validation no; // for private external dns
        // for forwarder.
        allow-recursion { any; };
        allow-recursion-on { any; };
        
	forwarders {
          8.8.8.8;
          8.8.4.4;
	};



	auth-nxdomain no;    # conform to RFC1035
	listen-on-v6 { any; };
	listen-on { any; };  #added 
};
```




test
```

/etc/init.d/bind9 restart

cat /etc/resolve.conf

dig @localhost pcfdemo.net
dig pcfdemo.net

dig  @localhost api.pcfdemo.net
dig api.pcfdemo.net

dig  @localhost a.apps.pcfdemo.net
dig a.apps.pcfdemo.net



```
