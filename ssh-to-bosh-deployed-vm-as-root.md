This document explains how to ssh into bosh deployed vms. and will explain how to get 'root' access to the vm.

1) ssh into jumpbox
- where you can access the bosh

2) generate sha-512 password (on ubuntu vm)

```
apt update
apt install whois -y

~$ mkpasswd -s -m sha-512 boshbosh
$6$HbFxBfEFH/YR.$uqC2eeHS4CnczDXw1smtT.MJtCzM/X1mTygadE8DuOpNBy5xddB1mHxFytnSrp1v.LAs2DltRkyYzos8kkjf50
```

3) get deployment manifest.yml from bosh.

```
bosh -d <DEPLOYMENT> manifest > deployment.yml
```

4) set vcap password to the vm deployment

```
vi deployment.yml
...
instance_groups:
- name: <DEPLOYMENT>
  instances: 1
  env:
    bosh:
      password: $6$HbFxBfEFH/YR.$uqC2eeHS4CnczDXw1smtT.MJtCzM/X1mTygadE8DuOpNBy5xddB1mHxFytnSrp1v.LAs2DltRkyYzos8kkjf50

```
5) deploy the deployment.

6) ssh into the deployment VM with opsman ssh key.
```
chmod 600 <OPSMAN_SSH_PRIVATE_KEY>
ssh -i <OPSMAN_SSH_PRIVATE_KEY> vcap@<TARGET_VM_IP>

Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.15.0-112-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
Last login: Mon Aug  3 03:29:10 UTC 2020 from 10.0.0.79 on pts/0
Last login: Mon Aug  3 03:35:55 2020 from 10.0.0.79
minio/77dffee3-0090-4412-872e-1a858aca7bc5:~$ whoami
vcap

```

7) switch to root with the vcap password.

```
minio/77dffee3-0090-4412-872e-1a858aca7bc5:~$ sudo su
[sudo] password for vcap:

minio/77dffee3-0090-4412-872e-1a858aca7bc5:/home/vcap# whoami
root
minio/77dffee3-0090-4412-872e-1a858aca7bc5:/home/vcap#

```

## ref
- https://community.pivotal.io/s/article/How-to-Override-Bosh-VCAP-password-of-an-on-demand-service?language=en_US.
- https://starkandwayne.com/blog/how-to-lock-vcap-password-for-bosh-vms/

