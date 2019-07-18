Monitoring k8s cluster via prometheus and grafana which is deployed in outside of K8s. currently it monitors one k8s cluster.


## prerequisites
- prometheus2 vm needs access to bosh director with port 8443(TBD)
- prometheus2 vm needs access to k8s master/worker with port 8443, 9100(TBD)

## install node-exporter addon to target k8s
- ref: https://github.com/bosh-prometheus/node-exporter-boshrelease

upload release to opsman bosh director
```
export BOSH_ENVIRONMENT=<name>
bosh upload-release https://github.com/bosh-prometheus/node-exporter-boshrelease/releases/download/v4.1.0/node-exporter-4.1.0.tgz

```
node-exporter-runtime-config.yml
```

releases:
  - name: node-exporter
    version: 4.1.0

addons:
  - name: node_exporter
    jobs:
      - name: node_exporter
        release: node-exporter
    include:
      stemcell:
        - os: ubuntu-trusty
        - os: ubuntu-xenial
    properties: {}


```

```
bosh update-runtime-config <your runtime-config.yaml file location>
```
then redeploy the k8s cluster.
```
bosh deploy...
```

## deploy prometheus cluster


```
git clone https://github.com/bosh-prometheus/prometheus-boshrelease

```
- run bosh-exporter job in prometheus2 VM(manifests/operators/monitor-bosh.yml). bosh-exporter will collect bosh metric and find node-exporter.
- run kube_state_metrics_exporter job in prometheus2 VM(manifests/operators/monitor-kubernetes.yml). kube_state_metrics_exporter will collect pod, container metrics via k8s api server. 
- let prometheus to crawl metrics kube_state_metrics_exporter job(manifests/operators/monitor-bosh.yml). this will collect kube_state_metric from kube_state_metrics_exporter job in prometheus2 VM.
```
 Prometheus Scrape Config
- type: replace
  path: /instance_groups/name=prometheus2/jobs/name=prometheus2/properties/prometheus/scrape_configs/-
  value:
    job_name: kube_state_metrics_exporter
    scrape_interval: 2m
    scrape_timeout: 1m
    static_configs:
      - targets:
        - localhost:9188
```

- deploy prometheus.
from https://github.com/bosh-prometheus/prometheus-boshrelease

``` 
bosh -d prometheus deploy manifests/prometheus.yml \
  --vars-store deployment-vars.yml \
  -o manifests/operators/monitor-bosh.yml 
  -o manifests/operators/enable-bosh-uaa.yml \
  -o manifests/operators/configure-bosh-exporter-uaa-client-id.yml \
  -o manifests/operators/monitor-kubernetes.yml \
  -o pcf-local-retention-policy.yml \
  -v bosh_url=<YOUR bosh director IP> \
  -v uaa_bosh_exporter_client_id=ops_manager \
  -v uaa_bosh_exporter_client_secret=xxxx\
  --var-file bosh_ca_cert=./director-ca \
  -v metrics_environment=<Any-name-to-be-shown-on prometheus> \
  -v kubernetes_apiserver_scheme=https \
   -v kubernetes_apiserver_ip=<YOUR-k8s-API> \
   -v kubernetes_apiserver_port=8443 \
  --var-file kubernetes_kubeconfig=./kube_mkim_config \
  -v kubernetes_bearer_token="xxxx" \
   -v skip_ssl_verify=true
```
where:
```
bosh_ca_cert:  copy from /var/tempest/workspaces/default/root_ca_certificate in opsman vm.
uaa_bosh_exporter_client_id: from opsman director
uaa_bosh_exporter_client_secret:  from opsman director
kubernetes_kubeconfig: copy from ~/.kube/config

kubernetes_bearer_token: get token by running: 
$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)


the toke can be tested by running:
export TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)
curl -X GET https://<your-k8s-cluster>:8443/api/v1/endpoints --header "Authorization: Bearer $TOKEN" —insecure

if there is error:
"message": "endpoints is forbidden: User \"system:serviceaccount:default:default\" cannot list resource \"endpoints\" in API group \"\" at the cluster scope”,

add priviledge to the service account:
kubectl create clusterrolebinding prometheus-exporter-cluster-admin \
    --serviceaccount=default:default \
    --clusterrole=cluster-admin

```

## access to prometheus
```
http://<prometheus-nginx-ip>:3000

id/password is from 'deployment-vars.yml' under prometheus bosh deployment.

```

## check metrics 
- ssh into prometheus2 vm.
- bosh-exporter test
```
curl -k localhost:9190/metrics

kubelet-*
```
- kube-state-metrics-exporter test:
ref: https://github.com/kubernetes/kube-state-metrics/tree/master/docs
```
curl -k localhost:9188/metrics

kube-*
```
```
http://<prometheus-nginx-ip>:9090

id/password is from 'deployment-vars.yml' under prometheus bosh deployment.

