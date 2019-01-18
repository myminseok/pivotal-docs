this setting is for ubuntu 14.04 jumpbox which is create by bbl 

## set shell to jumpbox user

jumpbox계정에  /bin/bash를 추가합니다.
~~~
$ sudo vipw

jumpbox:x:110:115::/home/jumpbox:/bin/bash

~~~

## default settng

~~~
vi ~/.profile

set -o vi
PS1='$(pwd) $ '
sudo mount -o remount,exec /tmp
~~~

## bbl
bbl명령이 에러나는 것을 방지하기 위해
~~~증상
jumpbox/0:~/bbl-aws$ bbl jumpbox-address

Run terraform output --json in vars dir: fork/exec /tmp/bbl-terraform: permission denied
~~~

~~~
mv /tmp/bbl-terraform /tmp/bbl-terraform.orig

~~~


## /tmp폴더에 실행모드 부여(ubuntu 14.6 trusty)
bbl up으로 생성되는 jumpbox는 /tmp mount에 noexec설정이 되어 있어서 이 폴더에 있는 실행파일의 실행이 불가능합니다.
이를 해결하기 위해 mount에 exec옵션을 부여해야합니다. 
특이한 점은 /tmp폴더는 jumpbox가 부팅되고 약 1분 후에 mount됩니다. 따라서 /etc/init.d보다는 jumpbox 계정의 .profile의 매 다음 명령을 추가하도록합니다.

vi /home/jumpbox/.profile
~~~ 
...

sudo mount -o remount,exec /tmp
~~~

재부팅합니다.
~~~
reboot -n
~~~


mount 명령으로 /tmp폴더의 상태를 확인합니다.
~~~
mount

결과에서  /tmp에 noexec가 없어야합니다.
~~~

## /tmp폴더에 실행모드 부여(ubuntu 16 xenial )
* root로 전환합니다.
~~~
sudo su
~~~
* vi  /etc/systemd/system/remount-tmp.service
~~~
[Unit]
Description=Remounts /tmp as rprivate to go back to previous behavior (before systemd)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/
ExecStart=/bin/mount -o remount,exec /tmp
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
~~~

* 부팅할때 활성화하기
~~~
systemctl enable remount-tmp
~~~

* 재부팅합니다.
~~~
reboot -n
~~~

* mount 명령으로 /tmp폴더의 상태를 확인합니다.
~~~
mount

결과에서  /tmp에 noexec가 없어야합니다.
~~~
