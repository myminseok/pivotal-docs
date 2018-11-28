monitoring k8s cluster using prometheus and grafana.

## prerequisite
- prepare k8s cluster. k8s cluster should be deployed with "Enable Privileged Containers", "Disable DenyEscalatingExec" option in PKS plan.
- pivotal cloud foundry opsman ui> pivotal container service> plan > check above option > apply changes.
- public internet access env from k8s cluster to dockerhub. 
- for airgapped-environment, see "setup helm chart server" in this doc.


## access to k8s dashboard from local PC
```
pks login
pks clusters
pks get-credentials <cluster-name>
kubectl proxy

open http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
```
## prepare local PC or jumpbox
###  helm
- guide: https://docs.helm.sh/using_helm/#installing-helm
- cli download: https://github.com/helm/helm/releases,
- cli linux amd64:  https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
- cli windows amd64: https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-windows-amd64.zip

### tiller (helm server module)
vi rbac-config.yaml 
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```
```
kubectl create -f rbac-config.yaml
helm init --service-account tiller
helm ls
```

## deploy prometheus

### prepare Persistent Volume Storage
Download the StorageClass spec for your cloud provider. 

```
wget https://raw.githubusercontent.com/cloudfoundry-incubator/kubo-ci/master/specs/storage-class-vsphere.yml

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: prometheus-storage                         
provisioner: kubernetes.io/vsphere-volume
allowVolumeExpansion: true                      
parameters:
  diskformat: zeroedthick
```  
- metadata.name: put any name
- allowVolumeExpansion: true ref:https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/

```
kubectl create -f ./storage-class-vsphere.yml
```

### helm prometheus deployment
https://github.com/helm/charts/tree/master/stable/prometheus

```
wget https://raw.githubusercontent.com/helm/charts/master/stable/prometheus/values.yaml
edit values.yml
or
https://github.com/myminseok/prometheus-grafana

server:
  ingress:
    enabled: true
    annotations:
       kubernetes.io/ingress.class: nginx
       kubernetes.io/tls-acme: 'true'
    hosts:
       - prometheus.pksdemo.net
    tls:
       - secretName: prometheus-server-tls
         hosts:
           - prometheus.pksdemo.net

  persistentVolume:
    enabled: true
    size: 4Gi
  ## Prometheus data retention period (i.e 360h)
  retention: ""
  
alertmanager:
  persistentVolume:
    enabled: true
    size: 2Gi
```

### deploy
```
# helm del --purge prometheus

helm install --name prometheus --set alertmanager.persistentVolume.storageClass=prometheus-storage,server.persistentVolume.storageClass=prometheus-storage -f ./helm-prometheus.yml stable/prometheus

```
wait until pods bound to volume. it takes time.
check namesspace event from k8s dashboard for troubleshooting.

### test prometheus

```
$ kubectl get pods
NAME                                             READY     STATUS    RESTARTS   AGE
prometheus-alertmanager-67b74bc4b9-jwdn8         2/2       Running   0          20h
prometheus-kube-state-metrics-5c88678db8-2v9cs   1/1       Running   0          20h
prometheus-node-exporter-5lffj                   1/1       Running   0          20h
prometheus-node-exporter-8xgp2                   1/1       Running   0          20h
prometheus-pushgateway-58bbb659-fr4f5            1/1       Running   0          20h
prometheus-server-5545f7cffc-6vxzt               2/2       Running   0          20h

$ kubectl port-forward prometheus-server-5545f7cffc-6vxzt 9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
Handling connection for 9090
```

open 127.0.0.1:9090 
![image](https://github.com/myminseok/prometheus-grafana/blob/master/prometheus-ui.png)




## deploy grafana

IMPORTANT: for airgapped environment, see install plugin while deploying pod (airgapped environment)

### helm grafana deployment

https://github.com/helm/charts/tree/master/stable/grafana

```
wget https://raw.githubusercontent.com/helm/charts/master/stable/grafana/values.yaml
or
https://github.com/myminseok/prometheus-grafana/blob/master/helm-grafana.yml
```

vi helm-grafana.yml
```
### install plugin while deploying pod (airgapped environment)
# 1. download plugin from https://grafana.com/plugins/grafana-kubernetes-app/installation
# 2. place grafana-kubernetes-app-31da38a.zip to local webserver
# 3. vi helm-grafana.yml

## Extra environment variables that will be pass onto deployment pods
env:
  GF_PLUGIN_URL: https://github.com/myminseok/prometheus-grafana/raw/master/grafana-kubernetes-app-31da38a.zip

plugins:
  - grafana-kubernetes-app 
    
```

### deploy
```
helm del --purge grafana

helm install --name grafana  -f ./helm-grafana.yml stable/grafana

```

## set up grafana dashboard

### access grafana dashboard

```
kubectl get pods
NAME                                             READY     STATUS    RESTARTS   AGE
grafana-8884d49f4-gqjhx                          1/1       Running   0          15h

$ kubectl port-forward <grafana-pod-name> 3000
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
Handling connection for 3000

$ kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
==> [admin password]

```

open 127.0.0.1:3000
admin / [password from the shell]


### configure grafana dashboard

configuration> datasource> add data source
- name: prometheus
- type: Prometheus
- http URL: http://prometheus-server.default.svc.cluster.local
- access: server(default)
- auth: no check anything
- skip TLS verification: no check
- whitelisted Cookies: blank
- scrape interval: 15s (default)
- Query timeout: 60s (default)
- HTTP Method: GET (default)

"Save & Test"

### grafana-kubernetes-app plugin
- plugin: https://grafana.com/plugins/grafana-kubernetes-app
- https://github.com/coreos/prometheus-operator/tree/master/helm/grafana


#### enable plugin dashboard 
https://github.com/grafana/kubernetes-app#connecting-to-your-cluster
- configuration> plugins> kubernetes > config> "enable"
- configuration> plugins> kubernetes > dashboard> import all dashboard.
now new kubernetes logo shows up on left ui.

#### create k8s dashboard
kubernetes> clusters > new cluster

- name: my-cluster1
- URL: https://my-cluster1.pksdemo.net:8443
- access: server(default)
- auth: TLS Client Auth
- skip TLS verification: checked
- TLS Auth details: get cert/key from k8s master vm.<br>
  ssh into k8s master > /var/vcap/jobs/kube-apiserver/config/var/vcap/jobs/prometheus.pem prometneus-key.pem, 
```

# ssh opsman vm 
# ssh into k8s master
bosh deployments
bosh ssh -d service-instance_8a0e0205-2ef0-4ee7-8a53-4824903a109c master
cd /var/vcap/jobs/kube-apiserver/config

# client cert: get the first cert from kubernetes.pem 
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----

# client key: kubernetes-key.pem
```
- advanced HTTP Setting> whitelisted cookies: blank
- prometheus read> datasource: prometheus

"save" and "deploy"

#### access to the k8s dashboard
kubernetes> clusters
![image](https://github.com/myminseok/prometheus-grafana/blob/master/k8s1.png)
![image](https://github.com/myminseok/prometheus-grafana/blob/master/k8s-cluster.png)



## troubleshooting

### setup helm chart server
https://medium.com/@maanadev/how-set-up-a-helm-chart-repository-using-apache-web-server-670ffe0e63c7

#### prepare ubuntu vm 
https://github.com/myminseok/ubuntu.apt.cache/blob/master/README.md

#### download helm chart on vm & setup nginx

```
cd /var/www/helm
mkdir -p index/charts
helm fetch stable/grafana -d ./index/charts
helm fetch stable/prometheus -d ./index/charts
helm repo index index/ --url http://127.0.0.1:8879
```
https://github.com/myminseok/ubuntu.apt.cache/blob/master/README.md#setup-nginx

#### helm repo add local

```
helm repo add local http://127.0.0.1:8879/charts

helm repo list
NAME  	URL
stable	https://kubernetes-charts.storage.googleapis.com
local 	http://127.0.0.1:8879/charts
```
now use 'local' instead of stable


### install plugin while deploying pod (airgapped environment)
1. download plugin from https://grafana.com/plugins/grafana-kubernetes-app/installation
2. place grafana-kubernetes-app-31da38a.zip to local webserver
3. vi helm-grafana.yml
```
## Extra environment variables that will be pass onto deployment pods
env:
  GF_PLUGIN_URL: https://github.com/myminseok/prometheus-grafana/raw/master/grafana-kubernetes-app-31da38a.zip
```
4. deploy pod.


### manually upload plugin (after grafana installation)
```
grafana-cli --pluginUrl https://nexus.company.com/grafana/plugins/<plugin-id>-<plugin-version>.zip plugins install <plugin-id>

export GF_PLUGIN_URL=https://github.com/myminseok/prometheus-grafana/raw/master/grafana-kubernetes-app-31da38a.zip
grafana-cli plugins install grafana-kubernetes-app

grafana-cli --pluginUrl https://github.com/myminseok/prometheus-grafana/raw/master/grafana-kubernetes-app-31da38a.zip plugins install grafana-kubernetes-app

```

### network chart doesn't show metrics
- grafana ui> kubernetes> clusters> my-cluster> container view > network(inbound) > edit>
```
rate(container_network_transmit_bytes_total{pod_name=~"$pod", kubernetes_io_hostname=~"$node"}[2m])
=> 
rate(container_network_transmit_bytes_total{pod_name=~"$pod"}[2m])
```
- check prometheus server ui for the container_network_transmit_bytes_total metric.

### file upload to pod
```
kubectl get pods
kubectl cp ./grafana-kubernetes-app-31da38a.tar.gz grafana-65b4bcc6fb-8rd67:/var/lib/grafana/plugins
kubectl exec -it <grafana-pod> -- /bin/bash


```
### k8s troubleshooting
https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#monitoring-compute-resource-usage

## TODO
how to exclude some useless metrics before collecting to prometheus?

