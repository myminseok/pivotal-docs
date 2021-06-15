
## server-side
```
sysctl -a | grep forward


sudo echo 1 > /proc/sys/net/ipv4/ip_forward
sudo vi /etc/sysctl.conf


#uncomment this line
net.ipv4.ip_forward=1
```

## client side
```
vi /etc/hosts
127.0.0.1 concourse.pcfdemo.net

ssh -i <ssh-private-key> -L <localhostip>:<localport>:<remotedb>:3306 YOUR-HOST-APP

ssh -i ssh-private-key -L 7443:192.168.1.150:7443 ubuntu@opsmgr-01.haas-224.pez.pivotal.io

```
