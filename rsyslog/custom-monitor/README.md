This guide describes how to collect system info process info and metric for troubleshooting and forward to external log server via rsyslog.

## Following system info can be collected every 10 second but it can be customizable:
- top 2 process with high cpu usage : ps aux --sort -rss 
- top 2 process with high memory usage every 10 second: ps -eo %cpu,%mem,rss,pid,user,command | sort -r 
- disk usage: df -h
- sshd daemon status

## Warning:
Note that this custom setup can be reverted on VM reboot or other events.

## How to setup
0. make sure the syslog forwarding setup to external rsyslog servier is done. refer to: [READMD.md](..//README.md)

1. customize the [setup-custom-monitor.sh](setup-custom-monitor.sh)

2. copy setup script into target instance_group where syslog forwarind is set.
```
bosh -d cf-f30f16d0a030d67be63a scp ./setup-custom-monitor.sh diego_cell:/tmp
```

3. execute the setup script; it will set custom-monitor service as a system service. this command can be run multiple times with no side-effects.

```
bosh -d cf-f30f16d0a030d67be63a ssh diego_cell -c "sudo cp /tmp/setup-custom-monitor.sh  /root/; sudo sh /root/setup-custom-monitor.sh"
```
process Ctrl + C to exit from bosh command after successful execution.

4. check custom-monitor service status
```
bosh -d cf-f30f16d0a030d67be63a ssh diego_cell -c "sudo systemctl status custom-monitor.service"
```

5. then the collected metric will be logged into /var/log/syslog on each VM periodically. and fowared to the external rsyslog server.

root@opsmanager-3-0:/var/log/rsyslog-tas# tail -f 192.168.0.76_syslog_2024-12-17.log

```
...
2024-12-17T10:08:12.776983+00:00 192.168.0.76 root 2024-12-17 10:08:12+00:00
2024-12-17T10:08:12.777224+00:00 192.168.0.76 root # HIGH_CPU: %CPU %MEM   RSS     PID USER     COMMAND
2024-12-17T10:08:12.777271+00:00 192.168.0.76 root 0.5  0.2 20428    4319 vcap     /var/vcap/packages/forwarder-agent/forwarder-agent
2024-12-17T10:08:12.777318+00:00 192.168.0.76 root 0.3  0.2 20456    3702 vcap     /var/vcap/packages/loggregator_agent/loggregator-agent
2024-12-17T10:08:12.777086+00:00 192.168.0.76 root # HIGH_MEMORY:  USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
2024-12-17T10:08:12.777133+00:00 192.168.0.76 root root        3625  0.0  0.5 1870744 41036 ?       Sl   09:01   0:00 /var/vcap/packages/containerd/bin/containerd -c /var/vcap/jobs/garden/config/containerd.toml
2024-12-17T10:08:12.777179+00:00 192.168.0.76 root vcap        4772  0.2  0.4 1779020 35576 ?       S<l  09:02   0:08 /var/vcap/packages/rep/bin/rep -config=/var/vcap/jobs/rep/config/rep.json
2024-12-17T10:08:12.777368+00:00 192.168.0.76 root # DISK usage: Filesystem      Size  Used Avail Use% Mounted on
2024-12-17T10:08:12.777418+00:00 192.168.0.76 root tmpfs           794M   83M  711M  11% /run
2024-12-17T10:08:12.777463+00:00 192.168.0.76 root /dev/sda2       4.8G  2.8G  1.8G  61% /
2024-12-17T10:08:12.777509+00:00 192.168.0.76 root tmpfs           3.9G     0  3.9G   0% /dev/shm
2024-12-17T10:08:12.777555+00:00 192.168.0.76 root tmpfs           5.0M     0  5.0M   0% /run/lock
2024-12-17T10:08:12.777601+00:00 192.168.0.76 root tmpfs           4.0M     0  4.0M   0% /sys/fs/cgroup
2024-12-17T10:08:12.777647+00:00 192.168.0.76 root /dev/sda1        48M  5.7M   43M  12% /boot/efi
2024-12-17T10:08:12.777692+00:00 192.168.0.76 root /dev/sdb2        56G  6.5G   46G  13% /var/vcap/data
2024-12-17T10:08:12.777742+00:00 192.168.0.76 root tmpfs            16M  552K   16M   4% /var/vcap/data/sys/run
2024-12-17T10:08:12.777795+00:00 192.168.0.76 root /dev/loop0       36G  2.4G   33G   7% /var/vcap/data/grootfs/store/unprivileged
2024-12-17T10:08:12.777841+00:00 192.168.0.76 root /dev/loop1       36G   69M   36G   1% /var/vcap/data/grootfs/store/privileged
2024-12-17T10:08:12.777886+00:00 192.168.0.76 root tmpfs           794M     0  794M   0% /run/user/1001
2024-12-17T10:08:12.777932+00:00 192.168.0.76 root tmpfs           2.8M     0  2.8M   0% /var/vcap/data/rep/shared/garden/instance_identity
2024-12-17T10:08:12.777978+00:00 192.168.0.76 root # SSHD status: ● ssh.service - OpenBSD Secure Shell server
2024-12-17T10:08:12.778024+00:00 192.168.0.76 root     Loaded: loaded (/lib/systemd/system/ssh.service; enabled; vendor preset: enabled)
2024-12-17T10:08:12.778069+00:00 192.168.0.76 root     Active: active (running) since Tue 2024-12-17 09:00:49 UTC; 1h 7min ago
2024-12-17T10:08:12.778129+00:00 192.168.0.76 root       Docs: man:sshd(8)
2024-12-17T10:08:12.778176+00:00 192.168.0.76 root             man:sshd_config(5)
2024-12-17T10:08:12.778221+00:00 192.168.0.76 root   Main PID: 639 (sshd)
2024-12-17T10:08:12.778267+00:00 192.168.0.76 root      Tasks: 1 (limit: 9438)
2024-12-17T10:08:12.778312+00:00 192.168.0.76 root     Memory: 5.5M
2024-12-17T10:08:12.778368+00:00 192.168.0.76 root     CGroup: /system.slice/ssh.service
2024-12-17T10:08:12.778414+00:00 192.168.0.76 root             └─639 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"
```


6. diable the custom-monitor service if donot need
```
bosh -d cf-f30f16d0a030d67be63a ssh diego_cell -c "sudo systemctl stop custom-monitor.service"
```
