https://docs.pivotal.io/p-concourse/4-x/authenticating.html
https://docs.pivotal.io/p-concourse/4-x/authenticating.html#config-cf

## pcf uaa에  concourse용 uaa client생성

~~~
ubuntu@opsmanager-2-2:~$   uaac target https://uaa.<system.pcf.com> --skip-ssl-validation

ubuntu@opsmanager-2-2:~$   uaac token client get admin -s [PAS.uaa.admin_client_credentials]


uaac client delete concourse_to_pcf

uaac client add concourse_to_pcf \
  --name concourse_to_pcf \
  --scope cloud_controller.read,openid \
  --authorized_grant_types "authorization_code,refresh_token" \
  --access_token_validity 3600 \
  --refresh_token_validity 3600 \
  --secret changeme \
  --redirect_uri https://<pcf.com>/sky/issuer/callback

~~~

### concourse 4.1.0 설치 (vsphere 기준)
concourse의 ATC모듈이 cf의 uaa에 인증을 하도록 설정하여 bosh를 이용해 concourse를 배포합니다. 설정을 위해  operations/cf-auth.yml 를 추가합니다. 

~~~
export concourse_url=https://<concourse url>

bosh -e d deploy -n --no-redact -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store cluster-creds.yml \
  -o operations/basic-auth.yml \
  -o operations/privileged-http.yml \
  -o operations/privileged-https.yml \
  -o operations/tls.yml \
  -o operations/tls-vars.yml \
  -o operations/scale.yml \
  -o operations/static-web.yml \
  -o operations/cf-auth.yml \
  --var web_ip=10.10.10.210 \
  --var network_name=concourse \
  --var external_url=https://<concourse url> \
  --var web_vm_type=medium \
  --var db_vm_type=medium.disk \
  --var worker_vm_type=large.disk \
  --var db_persistent_disk_type=db \
  --var web_instances=1 \
  --var worker_instances=1 \
  --var deployment_name=concourse \
  --var external_lb_common_name=<concourse url> \
  --var external_host=<concourse url> \
  --var concourse_host=<concourse url> \
  --var local_user.username=admin \
  --var local_user.password=<password> \
  --var cf_client_id=concourse_to_pcf \
  --var cf_client_secret=<password> \
  --var cf_api_url=https://api.<system.pcf.url> \
  -l ./<opsmanager.ca>

  # opsmanager.ca파일: ops manager vm내 /var/tempest/workspaces/default/root_ca_certificate의 내용을 추출하여 다음형태로 가공합니다.

  vi opsmanager.ca

  cf_api_ca_cert:
    certificate: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
~~~