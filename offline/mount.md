
## mount disk temporailry.
```
fdisk -l
mkfs.ext4 /dev/sdc
mkdir /data
mount /dev/sdc /data
```
## mount on VM boot
```
## copy UUID
blkid
ls -al /dev/disk/by-uuid/

## Edit fstab
vi  /etc/fstab
...
UUID=466b17a6-245f-4d3f-a5b2-ffa741bc7834 /data ext4 defaults 0 0

## success if nothing return.
sudo mount -a

## reboot 
reboot -n

## ssh login 

root@jumpbox:/home/ubuntu# mount | grep store
pstore on /sys/fs/pstore type pstore (rw,nosuid,nodev,noexec,relatime)
/dev/sdc on /store type ext4 (rw,relatime)

root@jumpbox:/home/ubuntu# df -h | grep store
/dev/sdc       492G   73M  467G   1% /store


```
https://confluence.jaytaala.com/display/TKB/Mount+drive+in+linux+and+set+auto-mount+at+boot
