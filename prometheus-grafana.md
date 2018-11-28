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
kubectl create -f storage-class-vsphere.yml
```
###

