
# prometheus설치 concourse파이프라인:
```
git clone https://github.com/pivotal-cf/pcf-prometheus-pipeline
```

# prometheus bosh-release git 소스가져오기:
```
git clone https://github.com/bosh-prometheus/prometheus-boshrelease

#하위모둘 가져오기
cd prometheus-boshrelease
git submodule update --init

#하위모듈 git이력 삭제
cd prometheus-boshrelease
rm -rf  ./src/github.com/kubernetes/kube-state-metrics/.git
rm -rf .git
git init
git add .
git commit -m "init"

# gitlab UI에서 prometheus-boshrelease생성
# git push
git remote add origin git@INTERNAL_GIT/platform/prometheus-boshrelease.git

```

# prometheus-bosh release 업로드 to minio

```
https://github.com/bosh-prometheus/prometheus-boshrelease

https://github.com/bosh-prometheus/prometheus-boshrelease/blob/master/manifests/prometheus.yml

releases:
- name: postgres
  version: "36"
  url: https://bosh.io/d/github.com/cloudfoundry/postgres-release?v=36
  sha1: 3dd10b417b21cfa3257f1cc891e9e46f02fefe16
- name: prometheus
  version: 25.0.0
  url: https://github.com/bosh-prometheus/prometheus-boshrelease/releases/download/v25.0.0/prometheus-25.0.0.tgz
  sha1: 71cf36bf03edfeefd94746d7f559cbf92b62374c



```


# docker container upload
참고: 
- http://INTERNAL_GIT/platform/pcf-prometheus-pipeline/blob/master/pipeline/pipeline.yml
- http://INTERNAL_GIT/platform/pcf-prometheus-pipeline/blob/master/pipeline/tasks/check-if-migration-required.yml

```
INTERNAL_HARBOR/mkuratczyk/bosh-creds-resource
INTERNAL_HARBOR/cloudfoundry/bosh-deployment-resource
INTERNAL_HARBOR/dojo/starkandwayne/concourse
```

# prometheus-bosh release git수정:
prometheus2 vm의 firehose_exporter job에 logging.url설정
```
http://INTERNAL_GIT/platform/prometheus-boshrelease/blob/master/manifests/operators/prometheus_firehose_exporter_logging_url.yml

- type: replace
  path: /instance_groups/name=prometheus2/jobs/name=firehose_exporter/properties/firehose_exporter/logging?/url?
  value: wss://doppler.((system_domain)):443
  
- type: replace
  path: /instance_groups/name=prometheus2/jobs/name=firehose_exporter/properties/firehose_exporter/logging/use_legacy_firehose?
  value: true

```

# prometheus설치 concourse 파이프라인 파라미터 편집:
```
https://github.com/pivotal-cf/pcf-prometheus-pipeline/blob/master/pipeline/params.yml
```

# prometheus retension policy 확인:
http://INTERNAL_GIT/platform/pcf-prometheus-pipeline/blob/master/pcf-local-retention-policy.yml


# main pipeline수정
http://INTERNAL_GIT/platform/pcf-prometheus-pipeline/blob/master/pipeline/pipeline.yml

# 배포
```
fly -t target set-pipeline -p deploy-prometheus -c pipeline/pipeline.yml -l your-params.yml
fly -t target unpause-pipeline -p deploy-prometheus
trigger create-uaa-clients job manually
trigger install-node-exporter job manually  => opsmanagerUI에서 PAS tile대상 pply change
trigger deploy job manually  => external bosh에 prometheus deployment
```

http://NGINX:3000
http://NGINX:9090


# 추가: grafana smtp
https://github.com/myminseok/pcf-prometheus-pipeline-minseok
