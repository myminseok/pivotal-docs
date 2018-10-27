
PAS UAA에 admin계정을 추가합니다.

1. opsmanager에 ssh로 로그인합니다.
~~~
ssh -i <opsmanager_ssh.keyfile> ubuntu@<opsman.url>
~~~

2. PAS UAA에 admin계정을 추가합니다.
~~~

uaac target https://uaa.system.<pcf-domain> --skip-ssl-validation

uaac token client get admin -s <PAS.uaa.admin_client_credentials>

uaac user add <new-admin> -p <PASSword> --emails admin@test.com
uaac member add cloud_controller.admin <new-admin>
uaac member add uaa.admin <new-admin>
uaac member add scim.read <new-admin>
uaac member add scim.write <new-admin>
~~~


## 참고
https://docs.pivotal.io/pivotalcf/2-2/uaa/uaa-user-management.html
