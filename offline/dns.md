## setup DNS

```
apt-get install bind9
```
```
sudo su
cd /etc/bind

cp db.local db.pcfdemo.net
pivotal@ubuntu:/etc/bind$ cat db.pcfdemo.net 


;
; BIND data file for local loopback interface
;
$TTL604800
@INSOApcfdemo.net. root.pcfdemo.net. (
      2; Serial
 604800; Refresh
  86400; Retry
2419200; Expire
 604800 ); Negative Cache TTL
;
@INNSpcfdemo.net.
@INA       192.168.0.100
vcenter     IN      A   192.168.0.6 
opsman     IN      A   192.168.0.11
*INA       192.168.0.100
@INAAAA::1
pivotal@ubuntu:/etc/bind$ cat db.apps.pcfdemo.net 
;
; BIND data file for local loopback interface
;
$TTL604800
@INSOAapps.pcfdemo.net. root.apps.pcfdemo.net. (
      2; Serial
 604800; Refresh
  86400; Retry
2419200; Expire
 604800 ); Negative Cache TTL
;
@INNSapps.pcfdemo.net.
@INA       192.168.0.100
*INA       192.168.0.100
@INAAAA::1
pivotal@ubuntu:/etc/bind$ 



pivotal@ubuntu:/etc/bind$ cat db.system.pcfdemo.net 
;
; BIND data file for local loopback interface
;
$TTL604800
@INSOAsystem.pcfdemo.net. root.system.pcfdemo.net. (
      2; Serial
 604800; Refresh
  86400; Retry
2419200; Expire
 604800 ); Negative Cache TTL
;
@INNSsystem.pcfdemo.net.
@INA       192.168.0.100
p-concourseINA       192.168.0.116
*INA       192.168.0.100
@INAAAA::1
pivotal@ubuntu:/etc/bind$ 

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
```
Named.conf.options에서 dnssec-validation no;로 설정해야함.


acl goodclients {
    192.168.0.0/24;
    localhost;
};
forwarders {
    8.8.8.8;
};
forward only;
dnssec-validation no;

```
test
```

/etc/init.d/bind9 restart
vi /etc/resolve.conf
ping a.system.pcfdemo.net
ping api.pcfdemo.net
ping pcfdemo.net
```
