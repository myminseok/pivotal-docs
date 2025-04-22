## NFS server and bind to apps on TAS

https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-platform-for-cloud-foundry/6-0/tpcf/services-using-vol-services.html

tested on:
- TAS 6.x
- ubuntu 20.04

## prepare nfs server

```
sudo apt update
sudo apt install nfs-kernel-server

sudo cat /proc/fs/nfsd/versions
-2 +3 +4 +4.1 +4.2

mkdir -p /data/nfs_data/

chown nobody:nogroup /data/nfs_data/


vi /etc/exports

/data/nfs_data  192.168.0.0/24(ro,sync,no_subtree_check)

sudo systemctl restart nfs-kernel-server

```


### test from nfs client

```
apt update
apt install nfs-common


mkdir /nfs/test

mount -t nfs -o vers=4 192.168.0.6:/data/nfs_data /nfs/test/


root@opsmanager-3-0:/home/ubuntu# df -h
Filesystem                  Size  Used Avail Use% Mounted on
tmpfs                       794M   69M  726M   9% /run
/dev/sda2                   158G   68G   84G  45% /
tmpfs                       3.9G     0  3.9G   0% /dev/shm
tmpfs                       5.0M     0  5.0M   0% /run/lock
tmpfs                       4.0M     0  4.0M   0% /sys/fs/cgroup
tmpfs                       3.9G   64K  3.9G   1% /home/tempest-web/ramdisk
tmpfs                       3.9G     0  3.9G   0% /run/qemu
/dev/sda1                    48M  5.7M   43M  12% /boot/efi
tmpfs                       794M     0  794M   0% /run/user/1002
192.168.0.6:/data/nfs_data  295G  151G  130G  54% /nfs/test

root@opsmanager-3-0:/nfs/test# ls -al /nfs/test/
total 2846892
drwxr-xr-x 2 nobody nogroup       4096 Apr 22 06:07 .
drwxr-xr-x 3 root   root          4096 Apr 22 06:09 ..
-rw-r--r-- 1 nobody nogroup 2915205120 Apr 22 06:06 Phi-4-mini-instruct-Q8_0.gguf


```

ref: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04
