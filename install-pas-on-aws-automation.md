
## 파이프라인 편집

~~~
git clone https://github.com/pivotal-cf/pcf-pipelines
~~~

### aws seoul region에 맞게 수정
- aws seoul region의 경우 az1, az2만 있으므로 az3제거하기
- NAT AMI변경
- Dev용으로 RDS대신 internal mysql사용하도록 변경
- PAS VM의 instance갯수를 조절할 수 있게 수정

위 내용을 반영한 수정된 파이프라인 참고: https://github.com/myminseok/pcf-pipelines-minseok


## fly cli설치
~~~
fly client download(linux):
wget https://github.com/concourse/concourse/releases/download/v4.2.1/fly_linux_amd64
~~~

### fly 로그인

~~~
fly -t sandbox login -c <concourse-url> -u <username> -p <password> -k 
~~~

## concourse에 파이프라인 생성하기
비밀번호가 담긴 파일은 별도 파라미터 파일로 관리하거나 credhub에 보관하도록 합니다.
~~~
cd pcf-pipelines/tree/master/install-pcf/aws
fly -t target sp -p install-pcf -c pipeline.yml -l ../../../params-aws.yml
~~~
