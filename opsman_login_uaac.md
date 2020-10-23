### ssh to Ops Manager VM
```
chmod 600 <opsmanager_ssh.keyfile>
ssh -i <opsmanager_ssh.keyfile> ubuntu@<opsman.url>
```

### uaac login
```
opsman$ uaac targets

opsman$ uaac target https://<opsman.domain.url>/uaa --skip-ssl-validation
Target: https://<opsman.domain.url>/uaa
Context: admin, from client opsman

opsman$  uaac token owner get
Client ID:  opsman
Client secret:
User name:  admin
Password:  <opsman ui admin password>

Successfully fetched token via owner password grant.
Context: admin, from client opsman

```
