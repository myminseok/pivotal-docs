

### Ops Manager VM에 ssh 접속하기
ops manager에 ssh 접속하기 위한 private key를 확보 후 ssh 접속합니다.
- https://docs.pivotal.io/pivotalcf/2-6/uaa/uaa-user-management.html

```
chmod 600 ops_mgr.pem
ssh -i ops_mgr.pem ubuntu@my-opsmanager-fqdn.example.com
```

### uaac login
```
# set target
uaac target https://uaa.<YOUR-PAS-SYS-DOMAIN> --ca-cert /var/tempest/workspaces/default/root_ca_certificate
ex)
uaac target https://uaa.sys.my.abc.com --ca-cert /var/tempest/workspaces/default/root_ca_certificate
Unknown key: Max-Age = 86400

Target: https://uaa.sys.my.abc.com


# get token
## Admin Client Credentials: opsman ui> pas tile > credentials> UAA Admin Client Credentials
uaac token client get admin -s <UAA-Admin Client Credentials>

Successfully fetched token via client credentials grant.
Target: https://uaa.sys..my.abc.com
Context: admin, from client admin
```

### add a user

```
uaac user add Adam -p newAdminSecretPassword --emails newadmin@example.com

$ uaac member add cloud_controller.admin Adam
$ uaac member add uaa.admin Adam
$ uaac member add scim.read Adam
$ uaac member add scim.write Adam


```
