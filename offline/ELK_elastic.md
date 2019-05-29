
## 구현 계획

아키텍처: https://docs.pivotal.io/pivotalcf/2-5/loggregator/architecture.html
그림: https://docs.pivotal.io/pivotalcf/2-5/loggregator/images/architecture/loggregator_2_4.png


ELK only: 
```
ELK(elastic.io)
logsearch bosh release(ELK, OSS, cloudfoundry community)
elastic-strack bosh release(ELK, OSS, elastic stack community)
```
ELK + PCF연동설정 자동화
```
logsearch for cloud foundry bosh release (OSS, cloudfoundry community): - logsearch bosh release가 설치되어있어야함. 
altoros log search for PCF(opsman tile, 상용): logsearch bosh release + logsearch for cloud foundry, PCF marketplace. kibana가 PCF UAA연동 권한관리
```

app 로그를 ELK에 저장하는 방법
1. cf cups log drain에 syslog endpoint를 설정하여 애플리케이션에 바인딩=>개발자가 알아서 연동
1. PCF의 loggregator firehose에 ELK nozzle을 적용해서 애플리케이션 로그를 ELK에 전달.: 플랫폼 범위에서 연동
- Platform log, metric: opsman UI> 각 tile에서 syslog endpoint에 ELK를 지정.
- app log, metric> ELK nozzle(logsearch for cloud foundry bosh release)를 적용.



## elastic-stack-bosh-deployment

https://github.com/bosh-elastic-stack/elastic-stack-bosh-deployment


0. download release and dependency
```
elastic stack bosh release

git clone https://github.com/bosh-elastic-stack/elastic-stack-bosh-deployment
cd elastic-stack-bosh-deployment
git checkout 7.0.0_2019-04-16
아래 파일의 release를 참조하여 download

- elastic-stack-bosh-deployment/elastic-stack.yml
- elastic-stack-bosh-deployment/version.yml

name: elastic-stack
releases:
- name: elasticsearch
  version: ((elasticsearch_version))
  url: https://github.com/bosh-elastic-stack/elasticsearch-boshrelease/releases/download/((elasticsearch_version))/elasticsearch-boshrelease-((elasticsearch_version)).tgz
  sha1: ((elasticsearch_sha1))
- name: logstash
  version: ((logstash_version))
  url: https://github.com/bosh-elastic-stack/logstash-boshrelease/releases/download/((logstash_version))/logstash-boshrelease-((logstash_version)).tgz
  sha1: ((logstash_sha1))
- name: kibana
  version: ((kibana_version))
  url: https://github.com/bosh-elastic-stack/kibana-boshrelease/releases/download/((kibana_version))/kibana-boshrelease-((kibana_version)).tgz
  sha1: ((kibana_sha1))
- name: openjdk
  version: ((openjdk_version))
  url: https://github.com/making/openjdk-boshrelease/releases/download/((openjdk_version))/openjdk-boshrelease-((openjdk_version)).tgz
  sha1: ((openjdk_sha1))
elasticsearch_version: 0.20.0
elasticsearch_sha1: 478f4d887a927add4b9d1b6ba9a6e0e52f97b01e
logstash_version: 0.12.0
logstash_sha1: e1556efc8f0eb679039b3f73adf994a5484821bc
kibana_version: 0.13.0
kibana_sha1: a18ed0650f166b861efefa0c199a367b8a9ab4c8
openjdk_version: 8.0.1
openjdk_sha1: d02566fb6d974de4b60bf44dc21e56422c7da3fd
nginx_version: 1.13.12
nginx_sha1: bf156c545c45ed4e57563274f91dbd433000d776
curator_version: 0.2.4
curator_sha1: 4dce7d5fe72681c7c147dea6e924a65bd1f9d57a
elastalert_version: 0.2.2
elastalert_sha1: f1c37995664c2311dc21cd78e21bd2c13f9fe3e6
cron_version: 1.1.3
cron_sha1: 69a98ea02ee5e8cc5a9ad2d6cd08ef0a7fa2c292

```

1. deploy
```
bosh -d elastic-stack deploy elastic-stack.yml \
     -l versions.yml \
     --var-file logstash.conf=logstash.conf \
     --no-redact
```

2. opsman tile > pas> syslog설정
3. app> syslog drain 설정.: 
-  https://docs.cloudfoundry.org/devguide/services/log-management.html#step1

