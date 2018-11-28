monitoring k8s cluster using prometheus and grafana.

## prerequisite
prepare k8s cluster.
public internet access env from k8s cluster to dockerhub.

## access to k8s dashboard
```
pks login
pks clusters
pks get-credentials <cluster-name>
kubectl proxy
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
```
## prepare jumpbox
###  helm
https://docs.helm.sh/using_helm/#installing-helm
download(linux amd64): https://github.com/helm/helm/releases, https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz

### tiller
rbac-config.yaml 
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

helm install --name prometheus --set alertmanager.persistentVolume.storageClass=ci-storage,server.persistentVolume.storageClass=ci-storage -f ./helm-prometheus.yml stable/prometheus

```



https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#monitoring-compute-resource-usage

## TODO
how to exclude some useless metrics before collecting.

