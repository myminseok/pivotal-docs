## setup NTP
```
apt-get update
apt-get install ntp
```

아래를 주석으로 하고 local을 추가. 127.127.1.0
```
vi /etc/ntp.conf

#server 0.ubuntu.pool.ntp.org
#server 1.ubuntu.pool.ntp.org
#server 2.ubuntu.pool.ntp.org
#server 3.ubuntu.pool.ntp.org
# Use Ubuntu's ntp server as a fallback.
#server ntp.ubuntu.com
server 127.127.1.0

```

```
service ntp restart

```
test
```
ntpq -pn
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*127.127.1.0     .LOCL.           5 l   27   64    7    0.000    0.000   0.000

root@ubuntu:~# ntpdate -u localhost
 2 Dec 13:46:58 ntpdate[3135]: adjust time server 127.0.0.1 offset -0.000005 sec
 
root@ubuntu:~# ntpdate -u 192.168.0.15
```
