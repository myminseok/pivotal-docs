# Setup DNS server (bind9, ubuntu)

#### download bind9 dependencies

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

#### setup ipv4 for bind9
vi /etc/default/bind9
```
OPTIONS="-4 -u bind"
```

#### /etc/bind$ vi db.pcfdemo.net 

```
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
pcf IN A       192.168.0.10
director IN A       192.168.0.11
*.sys IN A       192.168.0.100 <-- go router
login.sys IN A       192.168.0.100  <-- go router
*.login.sys IN A       192.168.0.100 <-- go router
uaa.sys IN A       192.168.0.100  <-- go router
*.uaa.sys IN A       192.168.0.100  <-- go router
*.apps IN A       192.168.0.100  <-- go router
ssh.sys IN A       192.168.0.200 <-- diego brain
@ IN AAAA ::1

```
#### /etc/bind$ vi named.conf.local 
```

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

```

#### lookup forwarder setting

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




#### test
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



#### systemd-resolver for ubuntu 18.04
```


https://www.linuxbabe.com/ubuntu/set-up-local-dns-resolver-ubuntu-18-04-16-04-bind9

root@jumpbox:/etc/bind# vi /etc/systemd/resolved.conf 

[Resolve]
DNS=127.0.0.1

root@platform-jumpbox:/etc/bind# systemctl restart systemd-resolved
root@platform-jumpbox:/etc/bind# systemd-resolve --status
Global
           
         DNS Servers: 10.10.10.5. ### <--- your DNS.
          DNSSEC NTA: 10.in-addr.arpa
                      16.172.in-addr.arpa
                      168.192.in-addr.arpa
                      17.172.in-addr.arpa
                      18.172.in-addr.arpa


```

or
vi /etc/netplan/00-installer-config.yaml
```
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens160:
      addresses:
      - 192.168.0.9/16
      gateway4: 192.168.0.1
      nameservers:
        addresses:
        - 127.0.0.1
  version: 2

```
sudo netplan apply

## Core DNS
- https://github.com/kubernetes/dns/blob/master/docs/specification.md
- https://coredns.io/plugins/kubernetes/
