## install a CA-certs to ubuntu

#### Copy your certificate in PEM format 
(the format that has ----BEGIN CERTIFICATE---- in it) into /usr/local/share/ca-certificates and name it with a .crt file extension

you may get CA from the domain site. 
```
root@opsmanager-2-8:/home/ubuntu# openssl s_client -connect api.system.pcfdemo.net:443
CONNECTED(00000003)
depth=0 C = US, O = Pivotal, CN = *.system.pcfdemo.net
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 C = US, O = Pivotal, CN = *.system.pcfdemo.net
verify error:num=21:unable to verify the first certificate
verify return:1
---
Certificate chain
 0 s:/C=US/O=Pivotal/CN=*.system.pcfdemo.net
   i:/C=US/O=Pivotal
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIDyjCCArKgAwIBAgIVAOxXXShrsfnherurCAZIDqkXQeX/MA0GCSqGSIb3DQEB
CwUAMB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMB4XDTE4MDgxNDE2
MjM1OFoXDTIwMDgxNDE2MjM1OFowPjELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bp
dm90YWwxHTAbBgNVBAMMFCouc3lzdGVtLnBjZmRlbW8ubmV0MIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwoRC94Doakj34YEVX7E8rl83JhKsQ62nYnK4


```
####  then copy the CA to /usr/local/share/ca-certificates/pcfdemo.net.crt 
```
printf -- "-----BEGIN CERTIFICATE-----
MIIDyjCCArKgAwIBAgIVAOxXXShrsfnherurCAZIDqkXQeX/MA0GCSqGSIb3DQEB
CwUAMB8xCzAJBgNVBAYTAlVTMRAwDgYDVQQKDAdQaXZvdGFsMB4XDTE4MDgxNDE2
MjM1OFoXDTIwMDgxNDE2MjM1OFowPjELMAkGA1UEBhMCVVMxEDAOBgNVBAoMB1Bp
dm90YWwxHTAbBgNVBAMMFCouc3lzdGVtLnBjZmRlbW8ubmV0MIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwoRC94Doakj34YEVX7E8rl83JhKsQ62nYnK4
-----END CERTIFICATE-----" > /usr/local/share/ca-certificates/pcfdemo.net.crt
```

#### install to /etc/ssl/certs
```
root@opsmanager-2-8:/home/ubuntu# update-ca-certificates
Updating certificates in /etc/ssl/certs...
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
	LANGUAGE = (unset),
	LC_ALL = (unset),
	LC_CTYPE = "UTF-8",
	LANG = "en_US.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to a fallback locale ("en_US.UTF-8").
WARNING: dhparam.pem does not contain a certificate or CRL: skipping
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

```
root@opsmanager-2-8:/home/ubuntu# find  /etc/ssl/certs/ -name "pcfdemo*"
/etc/ssl/certs/pcfdemo.net.pem
```

