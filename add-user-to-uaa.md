
PAS uaa module에 admin계정을 추가하는 방법을 설명합니다.
- https://docs.pivotal.io/pivotalcf/2-6/uaa/uaa-user-management.html


### Ops Manager VM에 ssh 접속하기
```
chmod 600 <opsmanager_ssh.keyfile>
ssh -i <opsmanager_ssh.keyfile> ubuntu@<opsman.url>
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

### add a user (as well as healthwatch dashboard)

```
uaac user add appsadmin -p PASSWORD --emails newadmin@example.com

uaac member add cloud_controller.admin appsadmin
uaac member add uaa.admin appsadmin
uaac member add scim.read appsadmin
uaac member add scim.write appsadmin

#  uaac member add healthwatch.admin appsadmin
```

### add a user for tanzu rabbitmq cluster dashboard

https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-rabbitmq-on-cloud-foundry/2-4/tanzu-rabbitmq-cloud-foundry/enable-oauth-for-rabbitmq.html

Enabling OAuth does not remove user credentials from service keys or from the internal backend of existing Tanzu RabbitMQ for Tanzu Application Service instances. However, you can no longer use these credentials to access the RabbitMQ Management UI.

```
$ cf space test --guid
27200c86-2e94-4f50-b645-2e4a0c3b57fc

ubuntu@opsmanager-3-0:~$ uaac group add p-rabbitmq_27200c86-2e94-4f50-b645-2e4a0c3b57fc.tag:administrator
...

ubuntu@opsmanager-3-0:~$ uaac member add p-rabbitmq_27200c86-2e94-4f50-b645-2e4a0c3b57fc.tag:administrator admin
success


open https://rmq-87106bb0-d0a5-418f-9049-05dd0e56af4f.sys.lab.pcfdemo.net

```