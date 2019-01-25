# Agile용어

1. pivotal tracker: agile 프로젝트를 수행할 때 프로젝트 일정을 관리해주는 협업도구. 팀의 속도를 자동으로 계산해주고 이에 따라 각 이터레이션의 일감을 자동으로 조절한다. concourse, git등과 연동이 된다. pivotaltracker.com
2. MVP: Minimun Viable Product,  고객에게 가치를 줄 수 있는 최소한의 기능셋. 고객의 피트백을 받아 개선하고자 하는 실험을 위한 목적이 큼. MVP의 품질도 매우 중요함. 
3. user story: pair programing으로 작업하는 일의 최소단위. 일의 목적을 사용자가 얻는 잇점을 중심으로 기술한다. As a <role>, I want <goal/desire> so that <benefit>  작업이 끝났을 때 성공조건을 반드시 명시한다. 
4. epic: user story의 그룹으로 일의 우선순위나 다른 일과의 구분을 위한 용도로 활용
5. icebox: 해야할 user story를 관리하는 저장고. 우선순위는 정해져 있지 않으며, PM이 관리한다.
6. backlog: 이번 iteration에서 해야 할 우선순위가 정해진 user story의 셋
7. pair programming: agile 방법론의 실천 방법중 하나. 둘이 같은 컴퓨터로 같은 일을 하는 것으로 보다 나의 의사결정, 높은 품질의 코드와 제품, 지식의 공유/전달의 잇점이 있고 궁극적으로 지속가능한 조직을 만드는데 목적이 있다.
8. persona: 역할의 특징을 나타낸다. developer, platform engineer등.


# 지속적인 빌드/배포(CI/CD) 관련 용어
1. control plane:  클라우드 상에서 배포되고 운용되는 여러 플랫폼(Pivotal Cloud Foundry Platform, MySQL Platform, Pivotal Ops Manager등)을 자동화하여 관리학 위한 도구의 집합. 주로 Jumpbox(작업VM), concourse(CI/CD도구. concourse-ci.org), 필요에 따라 docker registry, S3, git repo등이 포함된다.
https://docs.pivotal.io/pivotalcf/2-0/refarch/control.html#placement
2. jumpbox: 작업 VM. http://bosh.io/docs/terminology/#jumpbox
3. BOSH(보쉬): 클라우드를 활용하는 대규모 분산 클러스터의 개발, 배포, 운영을 담당하는 오픈소스 도구이다. 주요 기능으로는 1) AWS, GCP, Azure, vmware, openstack등의  IaaS제공자가 제공하는 CPI(Cloud Provider Interface)를 통해 VM, Disk, Network등의 자원을 생성,삭제,수정을 직접 통제할 수 있기 때문에  클러스터를 직접 배포(provisioning). 2) 그리고 직접 배포한 클러스터의 운영을 담당하여 장애가 발생한 VM, VM내의 프로세스를 스스로 복구(자가치유) 3) 클러스터를 구성하는 소프트웨어(플랫폼 패키지)의 배포판을  제작할 수 있다..(BOSH릴리즈) 
http://bosh.io
4. BOSH RELEASE: 클러스터를 구성하는 소프트웨어(플랫폼 패키지, configuration template)의 배포판으로 bosh를 통해 만든다. http://bosh.io/docs/terminology/#release
5. stemcell: VM OS image+ bosh agent http://bosh.io/docs/terminology/#stemcell
6. bosh deployment manifest: bosh release를 배포하기 위한 설정정보  http://bosh.io/docs/terminology/#manifest
7. bosh deployment: stemcell + bosh release + bosh deployment manifest를 이용해 bosh가 배포한 클러스터. bosh deployments 명령으로 확인.
8. concourse: Pivotal이 만든 오픈소스 지속빌드/지속배포(CI/CD)도구.  pipeline을 소스코드로서 관리하는 것이 특징으로 언제 어디서든 파이프라인을 즉시 만들어내고 변경이력을 관리할 수 있다. concourse-ci.org
9. CI/CD 파이프라인: 소프트웨어의 빌드부터 배포까지 담당하는 자동화된 workflow로 주로, concourse 또는 jenkins에 구성한다.
10. credhub: pivotal이 만든 오픈소스 암호화 저장소 도구. 인증서, 비밀번호등을 생성, 저장, 조회할 수 있는 key-value저장소이다. UAA와 연동할 경우(concourse, PAS) UAA가 관리하는 인증 정보를 저장하여 플랫폼 자체 데이터의 보안을 강화한다. 개발자의 애플리케이션에서 연동하여 인증정보를 저장하여 보안을 강화할 수 있다.  https://github.com/pivotal-cf/credhub-release
11. BBL:Bosh BootLoader의 약자로,  jumpbox, bosh, terraform을 통한 네트워크 자동생성을 위한  CLI도구 https://github.com/cloudfoundry/bosh-bootloader
12. BBR: Bosh Backup and Restore의 약자. BOSH deployment와 BOSH director를 백업하고 복구하기 위한 CLI도구 https://github.com/cloudfoundry-incubator/bosh-backup-and-restore
13. Errand: bosh deployment 실행시 한번만 실행되는 job으로 예들들어 deployment testcase, deployment compile등이 실행된다. http://bosh.io/docs/terminology/#errand


# Pivotal Cloud Foundry 관련용어

1. PCF foundation: Pivotal Cloud Foundry 플랫폼을 자동화하여 관리하기 위한 도구 셋(Pivotal Ops Manager, BOSH)이 배포된 클러스터 1개를 말한다. PCF foundation은 concourse 파이프라인에 의해 자동으로 설치, 업그레이드 된다.
2.  Droplet: PAS(Pivotal Application Service)의 내부에서 자동으로 생성하는 애플리케이션을 위한 컨테이너 이미지를 부르는 이름.  애플리케이션을 cloud foundry 명령 도구를 이용하여 배포할 때 자동으로 생성된다. cf push (http://cli.cloudfoundry.org/en-US/cf/push.html)
애플리케이션의 실행코드(java의 경우 jar파일, python의 경우 소스코드)만 플랫폼으로 던져주면 java의 경우 애플리케이션의 실행에 필요한 JVM, framework을 PaaS플랫폼 내부에서 불러와 애플리케이션과 조합하여 최적의 컨테이너 이미지를 동적으로 만들어낸다. 만약 보안패치등의 이유로 JVM, framework, application등의 구성요소 중에 하나가 바뀌더라도 언제든 재조합이 가능하므로 자동화효율성이 향상되고, 컨테이너 이미지는 플랫폼에서 자동으로 관리하므로 플랫폼 관리자, 애플리케이션 관리자의 부담을 덜어준다. 
3. domains: PAS(Pivotal Application Service) 상에서 서비스 되는 애플리케이션이 사용할 서비스 도메인, ex)  shared-domain.example.com
애플리케이션은 sub-domain을 자동으로 할당받아 publish된다. ex) myapp.shared-domain.example.com
4. managed service:  Pivotal Cloud Foundry의 API를 통해 사용자가 셀프서비스로 사용할 수 있는  제3자가 제공하는 서비스
5. orgs: PAS(Pivotal Application Service)상에서 개발팀이 애플리케이션을 개발하고 배포할 수 있는 논리적인 공간, 주로 서비스를 공동 개발하는 팀등의 조직구조와 매핑된다.
6. routes: domains에 sub-domain으로 할당되어 애플리케이션과 바인드 되는 서비스 주소를 말함. PAS(Pivotal Application Service)에서 하나의 애플리케이션은 여러개의 route를 가질 수 있고 셀프서비스로 조작이 가능하다.  ex) myapp.shared-domain.example.com
7. service: MySQL, Redis, RabbitMQ등과 같이 애플리케이션에서 사용할 수 있는 백엔드 서비스를 말함. PAS(Pivotal Application Service)상의 마켓플레이스에 노출되어 셀프서비스로 service instance를 생성할 수 있다. 이런 서비스는 bosh-release로 만들어지는데 플랫폼 관리자에 의해 관리된다.
8. service instance: service로 부터 생성된 instance. 두가지 셀프서비스 모델이 있는데,  MySQL for PCF의 경우 운영자에 의해 미리 만들어진 공용 MySQL클러스터에 self-service로 schema, user만 만들어 사용하는 것과, self-service로 독립적인 MySQL클러스터를 생성(provisioning)할 수 있다.
9. UAA: cloud foundry의 프로젝트 중의 하나로 OAuth2프로토콜을 기반으로 사용자의 인증을 담당한다.(User Account Authentication)
