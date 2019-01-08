

control-plane의 concourse는 비밀번호, 인증서등을 암호화해서 안전하게 저장하기 위해 bosh-director VM 내의 credhub를 사용할 것입니다.
이를 위해  bosh director VM안의 uaa모듈에 concourse가 사용할 uaa client를 등록합니다.

## uaac설치
[jumpbox에 bosh cli환경 설정](install_bosh_cli.md)를 참고하여 ruby환경을 구성합니다.
그리고 gem을 통해 uaac를 설치합니다.

~~~
gem install cf-uaac
~~~

## uaa에 credhub client생성
참고: https://docs.cloudfoundry.org/uaa/uaa-user-management.html
~~~
uaac target https://10.0.0.6:8443 --skip-ssl-validation

uaac token client get uaa_admin -s [uaac_admin_secret] 
  => password는 bbl > vars/director_vars_store.yaml에서 추출
  
uaac client add concourse_to_credhub --authorities "credhub.read,credhub.write" \
    --scope "" --authorized-grant-types "client_credentials"
  => authorities, scope 권한 참조: https://github.com/pivotal-cf/pcf-pipelines/blob/master/docs/credhub-integration.md#uaa-client-setup
~~~

## credhub동작 테스트

download credhub cli: https://github.com/cloudfoundry-incubator/credhub-cli/releases

~~~
bbl환경정보에서 credhub_ca/ca 또는 certificate 추출
bosh int ./vars/director-vars-store.yml --path /credhub_ca/ca > credhub.ca
chmod +x crecdhub.ca
~~~

~~~
./credhub api -s https://10.0.0.6:8844 --ca-cert [앞에서 만든 credhub.ca파일 경로]  --skip-tls-validation
Warning: The targeted TLS certificate has not been verified for this connection.
Warning: The --skip-tls-validation flag is deprecated. Please use --ca-cert instead.
=> 이 메시지가 나오면 성공한 것임

./credhub login --client-name=concourse_to_credhub --client-secret=[앞서 생성한 concourse_to_credhub client의 비밀번호]
./credhub set -n /test -t value
./credhub get -n /test
~~~

## key lookup모델
bosh deployment에서 credhub의 key를 참조할때는 다음의 순서로 참조합니다.
~~~
/bosh deployment 명/concourse팀명/pipeline명/key
~~~
concourse의 경우 다음과 같습니다.
~~~
/concourse/main/pipeline-name/key-name
~~~
