
# harbor( docker-compose)

download: https://github.com/goharbor/harbor/releases

wget https://github.com/goharbor/harbor/releases/download/v2.3.3/harbor-offline-installer-v2.3.3.tgz

tar xf harbor-offline-installer-v2.3.3.tgz


###  HTTPS harbor
https://goharbor.io/docs/2.0.0/install-config/configure-https/


cp harbor.yml.tmpl harbor.yml

infra-harbor.lab.pcfdemo.net

https:
  # https port for harbor, default is 443
  port: 443
  # The path of cert and key files for nginx
  certificate: /data/harbor-main/generate-self-signed-cert-new/domain.crt
  private_key: /data/harbor-main/generate-self-signed-cert-new/domain.key


/data/harbor-main/harbor# docker-compose version

docker-compose version 1.26.2, build unknown
docker-py version: 4.4.4
CPython version: 2.7.17
OpenSSL version: OpenSSL 1.1.1  11 Sep 2018

sudo ./install.sh

sudo chown -R ubuntu:ubuntu /data/

docker-compose up

# troubleshooting: wget download failure
```
wget https://cli.run.pivotal.io/stable?release=debian64&source=github

root@DojoJump:/etc/ssl# --2019-04-09 16:29:55-- https://cli.run.pivotal.io/stable?release=debian64
Resolving cli.run.pivotal.io (cli.run.pivotal.io)... 34.204.136.114, 34.194.131.211
Connecting to cli.run.pivotal.io (cli.run.pivotal.io)|34.204.136.114|:443... connected.
ERROR: cannot verify cli.run.pivotal.io's certificate, issued by emailAddress=admin@abc.com,CN=ABC,OU=ABC,O=ABC,L=ABC,ST=ABC,C=KR:
Self-signed certificate encountered.
To connect to cli.run.pivotal.io insecurely, use `--no-check-certificate'

```

how to import ABC corp certificate
```
1) export ABC corp cert(DER format)
2) copy to External jumpbox (ubuntu)
3) convert DER to PEM

openssl x509 -inform der -outform pem -in ABC.cer -out ABC.pem

4) cp ABC.pem /usr/local/share/ca-certificates/ABC.crt
Please note that the certificate filenames have to end in .crt, otherwise the update-ca-certificates script won't pick up on them.

5) root@DojoJump:/etc/ssl# update-ca-certificates
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.

wget https://cli.run.pivotal.io/stable?release=debian64&source=github
```

