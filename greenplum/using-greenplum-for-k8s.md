This document describes how to deploy a new greenplum for k8s. based on https://greenplum-kubernetes.docs.pivotal.io/1-2/deploy-operator.html


# Prerequisites
- have kubernetes cluster (via PKS 1.2+) (https://greenplum-kubernetes.docs.pivotal.io/1-2/prepare-pks.html)
- provisioned greenplum-operator to k8s (https://greenplum-kubernetes.docs.pivotal.io/1-2/installing.html)
- installed kubectl, pks cli (https://network.pivotal.io/products/pivotal-container-service/)
```
chmod +x pks-darwin-amd64-1.4.0-build.230
sudo mv pks-darwin-amd64-1.4.0-build.230 /usr/local/bin/pks

chmod +x kubectl-darwin-amd64-1.13.5
sudo mv kubectl-darwin-amd64-1.13.5 /usr/local/bin/kubectl
```


# How to create new greenplum cluster

## get credentials for k8s

```
$ pks login -a <PKS-API-URL> -u <PKSADMIN> -p <PASSWORD> --skip-ssl-validation
ex) pks login -a api.my-pksdomain.com -u my-pks-admin -p my-secure-password --skip-ssl-validation


$ pks clusters
Name        Plan Name  UUID                                  Status     Action
my-cluster  medium     29f0ea12-20a1-41b3-a6e2-28b337be5474  succeeded  CREATE


$ pks cluster my-cluster
Name:                     my-cluster
Plan Name:                medium
UUID:                     29f0ea12-20a1-41b3-a6e2-28b337be5474
Last Action:              CREATE
Last Action State:        succeeded
Last Action Description:  Instance provisioning completed
Kubernetes Master Host:   my-cluster.my-pkscluster.com
Kubernetes Master Port:   8443
Worker Nodes:             5
Kubernetes Master IP(s):  10.10.14.33, 10.10.14.34, 10.10.14.32
Network Profile Name:



$ pks get-credentials my-cluster
Fetching credentials for cluster my-cluster.
Context set for cluster my-cluster.
You can now switch between clusters by using:
$kubectl config use-context <cluster-name>

```

## setup kubectl

check and edit "clusters.cluter.server" to the right url and port to direct k8s masters.

```
vi ~/.kube/config


apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: xxxxxxx
    server: https://my-cluster.my-pkscluster.com:8443
  name: my-cluster

```

check connection
```
$  kubectl cluster-info
Kubernetes master is running at https://my-cluster.my-pkscluster.com:8443
CoreDNS is running at https://my-cluster.my-pkscluster.com:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'

```


## check greenplum-operator status
deployment.apps/greenplum-operator should be up and running. otherwise install following https://greenplum-kubernetes.docs.pivotal.io/1-2/installing.html

```
$ kubectl get all

NAME                                      READY   STATUS    RESTARTS   AGE
pod/greenplum-operator-86b86d8444-djsvw   1/1     Running   0          10h

NAME                                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/agent                          ClusterIP      None             <none>        22/TCP           30m
service/kubernetes                     ClusterIP      10.100.200.1     <none>        443/TCP          25h

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/greenplum-operator   1/1     1            1           19h

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/greenplum-operator-86b86d8444   1         1         1       19h

```

## access k8s dashboard
refer to https://docs.pivotal.io/runtimes/pks/1-4/access-dashboard.html
```
$ cp ~/.kube/config ~/Downloads


$ kubectl proxy
Starting to serve on 127.0.0.1:8001

```

access with browser http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/ and use '~/Downloads/config' file for authentication

## check k8s events for troubleshooting

```
$ kubectl get events --all-namespaces -w

NAMESPACE    LAST SEEN   TYPE      REASON                     KIND                    MESSAGE
default      34m         Normal    ProvisioningSucceeded      PersistentVolumeClaim   Successfully provisioned volume pvc-f5622cae-9878-11e9-bec4-00505696f3cb using kubernetes.io/vsphere-volume
default      34m         Normal    ProvisioningSucceeded      PersistentVolumeClaim   Successfully provisioned volume pvc-f5672960-9878-11e9-bec4-00505696f3cb using kubernetes.io/vsphere-volume
default      34m         Normal    ProvisioningSucceeded      PersistentVolumeClaim   Successfully provisioned volume pvc-f576200d-9878-11e9-bec4-00505696f3cb using kubernetes.io/vsphere-volume
default      34m         Normal    ProvisioningSucceeded      PersistentVolumeClaim   Successfully provisioned volume pvc-f581013f-9878-11e9-bec4-00505696f3cb using kubernetes.io/vsphere-volume
default      34m         Normal    CreatingGreenplumCluster   GreenplumCluster        Creating Greenplum cluster gp-test in default
default      32m         Normal    CreatedGreenplumCluster    GreenplumCluster        Successfully created Greenplum cluster gp-test in default
default      35m         Normal    Killing                    Po

```


## create namespace for greenplum.
from now on, refer to https://greenplum-kubernetes.docs.pivotal.io/1-2/deploy-operator.html

```
$ kubectl create namespace gpinstance-1
$ kubectl create namespace gpinstance-2

$ kubectl get namespaces

NAME          STATUS    AGE
default       Active    50d
gpinstance-1  Active    50d 
gpinstance-2  Active    50d 
kube-public   Active    50d
kube-system   Active    50d
```


## create storage class

vi storage-class-vsphere.yml
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: standard
provisioner: kubernetes.io/vsphere-volume
parameters:
  diskformat: zeroedthick  
```

```
$ kubectl apply -f storage-class-vsphere.yml

$ kubectl get storageclasses
NAME       PROVISIONER                    AGE
standard   kubernetes.io/vsphere-volume   85m
```


## create a new greenplum cluster 

vi my-gp-instance.yaml
```
apiVersion: "greenplum.pivotal.io/v1"
kind: "GreenplumCluster"
metadata:
  name: my-greenplum
spec:
  masterAndStandby:
    hostBasedAuthentication: |
      # host   all   gpadmin   1.2.3.4/32   trust
      # host   all   gpuser    0.0.0.0/0   md5
    memory: "800Mi"
    cpu: "0.5"
    storageClassName: standard
    storage: 1G
    antiAffinity: yes
  segments:
    primarySegmentCount: 1
    memory: "800Mi"
    cpu: "0.5"
    storageClassName: standard
    storage: 2G
    antiAffinity: yes

```

### creating cluster at default namespace 

creating... it takes time to init state from "PENDING" to "RUNNING"
```
$ kubectl apply -f my-gp-instance.yaml

$ kubectl get all
NAME                                      READY   STATUS    RESTARTS   AGE
pod/greenplum-operator-86b86d8444-djsvw   1/1     Running   0          10h
pod/master-0                              1/1     Running   0          41m
pod/master-1                              1/1     Running   0          41m
pod/segment-a-0                           1/1     Running   0          41m
pod/segment-b-0                           1/1     Running   0          41m

NAME                                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/agent                          ClusterIP      None             <none>        22/TCP           41m
service/greenplum                      LoadBalancer   10.100.200.69    <pending>     5432:32559/TCP   41m
service/greenplum-validating-webhook   ClusterIP      10.100.200.213   <none>        443/TCP          10h
service/kubernetes                     ClusterIP      10.100.200.1     <none>        443/TCP          25h

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/greenplum-operator   1/1     1            1           19h

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/greenplum-operator-86b86d8444   1         1         1       19h

NAME                         READY   AGE
statefulset.apps/master      2/2     41m
statefulset.apps/segment-a   1/1     41m
statefulset.apps/segment-b   1/1     41m

NAME                                            STATUS    AGE
greenplumcluster.greenplum.pivotal.io/gp-test   Running   42m
```

creating multiple cluster at different namespace
```
$ kubectl apply -f my-gp-instance.yaml -n gpinstance-1
$ kubectl apply -f my-gp-instance.yaml -n gpinstance-2
```


## test cluster.

```
$ kubectl exec -it master-0 bash -- -c "source /opt/gpdb/greenplum_path.sh; psql"

psql (8.3.23)
Type "help" for help.

gpadmin=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port  |               
  hostname                 |                   address                   | repli
cation_port 
------+---------+------+----------------+------+--------+-------+---------------
---------------------------+---------------------------------------------+------
------------
    1 |      -1 | p    | p              | s    | u      |  5432 | master-0      
                           | master-0.agent.default.svc.cluster.local    |      

```

put namespace option '-n' to access different gpdb cluster.
```
$ kubectl exec -it master-0 -n gpinstance-1 bash -- -c "source /opt/gpdb/greenplum_path.sh; psql"

```

## delete cluster

```
$ kubectl delete -f my-gp-instance.yaml

$ kubectl get all

## check events

$ kubectl get events --all-namespaces -w

```
