
## 기본 작업 
다음 PCF 시스템을 다루기 위한 기본적인 작업에 대한 가이드입니다.

### Ops Manager VM에 ssh 접속하기
ops manager에 ssh 접속하기 위한 private key를 확보 후 ssh 접속합니다.

```
chmod 600 ops_mgr.pem
ssh -i ops_mgr.pem ubuntu@my-opsmanager-fqdn.example.com
```

### BOSH director에 login
PAS 를 관리하는 bosh director에 로그인하는 방법입니다.
1.	Ops Manager UI > director tile> credentials tab > Bosh Commandline Credentials> Link to credential 클릭하여 아래 형식의 내용을 복사
2.	Ops Manager VM에 ssh접속
3.	vi ~/.profile에 아래 형태로 편집하여 저장
```
alias bosh=" BOSH_CLIENT=ops_manager BOSH_CLIENT_SECRET=xxxx BOSH_CA_CERT=/var/tempest/workspaces/default/root_ca_certificate BOSH_ENVIRONMENT=10.10.10.21 bosh"


export BOSH_CLIENT=ops_manager 
export BOSH_CLIENT_SECRET=xxxx 
export BOSH_CA_CERT=/var/tempest/workspaces/default/root_ca_certificate 
export BOSH_ENVIRONMENT=10.10.10.21
```
4.	환경정보 활성화
```
source  ~/.profile
```
5.	Bosh 환경정보 조회
결과가 아래와 같이 나오면 정상입니다.
```
ubuntu@opsmanager-2-4:~$ bosh env
Using environment '10.10.10.21' as client 'ops_manager'

Name      p-bosh
UUID      2117b308-7f9b-4dd4-9fde-5916e7f3049c
Version   268.2.2 (00000000)
CPI       vsphere_cpi
Features  compiled_package_cache: disabled
          config_server: enabled
          local_dns: enabled
          power_dns: disabled
          snapshots: disabled
User      ops_manager

Succeeded
```
