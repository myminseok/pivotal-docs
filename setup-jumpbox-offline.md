
# jumpbox 
- os: ubuntu xenial 16.04 LTS, 64 bit 
- http://releases.ubuntu.com/xenial/

# download all  dependencies from internet
- https://bosh.io/docs/cli-v2-install
```
sudo su

# bosh depencencies
mkdir bosh-binaries
cd bosh-binaries


apt-get download  build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3
ls -al *.deb
tar zcf bosh-binaries.tar.gz ./bosh-binaries

# bosh cli
wget https://github.com/cloudfoundry/bosh-cli/releases/download/v5.4.0/bosh-cli-5.4.0-linux-amd64

# cf cli
wget https://docs.cloudfoundry.org/cf-cli/install-go-cli.html#pkg-linux
wget -O cf.deb https://cli.run.pivotal.io/stable?release=debian64&source=github

```
copy to internal jumpbox
```
tar xf bosh-binaries.tar.gz
cd bosh-binaries/
dpkg -i *.deb
apt-get install -f
apt list --installed


mv bosh-cli-5.4.0-linux-amd64 /usr/local/bin/bosh

```


# install docker engine
- 외부에서 내려받은 다커 이미지를 내부 하버에 밀어넣기 위해 내부 점프박스에 다커 엔진이 필요하다. 
- 외부 점프박스에서 받아 설치해보고 내부 점프박스에 설치.
```
sudo su
apt-get download libltdl7
apt download docker.io
```
copy to internal jumpbox
```
sudo su
dpkg -i libltdl7_2.4.6-0.1_amd64.deb 
dpkg -i docker.io_18.09.2-0ubuntu1~16.04.1_amd64.deb 
apt-get install -f
root@TLKPCFJB1:/home/ubuntu# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

```


# install certificate to jumpbox
```

1) get cert in DER format
2) DER -> PEM 
openssl x509 -inform der -outform pem -in my.cer -out my.pem

3) cp my.pem /usr/local/share/ca-certificates/my.crt
Please note that the certificate filenames have to end in .crt, otherwise the update-ca-certificates script won't pick up on them.

4) root@DojoJump:/etc/ssl# update-ca-certificates
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.

```

