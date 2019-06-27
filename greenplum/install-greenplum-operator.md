
This document describes how to deploy greenplum for k8s. based on https://greenplum-kubernetes.docs.pivotal.io/1-2/installing.html
if your k8s cluster is not ready, [install k8s using PKS](/greenplum/install-pks-vsphere.md)
### Prerequisites
- have kubernetes cluster (via PKS 1.2+) (https://greenplum-kubernetes.docs.pivotal.io/1-2/prepare-pks.html)
- installed kubectl, pks cli (https://network.pivotal.io/products/pivotal-container-service/)
```
chmod +x pks-darwin-amd64-1.4.0-build.230
sudo mv pks-darwin-amd64-1.4.0-build.230 /usr/local/bin/pks

chmod +x kubectl-darwin-amd64-1.13.5
sudo mv kubectl-darwin-amd64-1.13.5 /usr/local/bin/kubectl
```
- installed docker on jumpbox
- have a private docker-registry(optional)

# Install greenplum-operator
see  https://greenplum-kubernetes.docs.pivotal.io/1-2/installing.html

### download greenplum-for-kubernetes from network.pivotal.io

```
tar xzf greenplum-for-kubernetes-*.tar.gz
cd ./greenplum-for-kubernetes-*

docker load -i ./images/greenplum-for-kubernetes
docker load -i ./images/greenplum-operator

```


### upload images to private-docker-registry
login to docker registry
``` 
docker login harbor.pks-domain.com -u admin -p xxx
```

create a project on rivate-docker-registry
```
https://harbor.pks-domain.com/greenplum
```

prepare script

```
$ cd ./greenplum-for-kubernetes-*

$ vi upload-images.sh




#!/bin/bash
## https://greenplum-kubernetes.docs.pivotal.io/1-2/installing.html
##

if [ -z $1 ]; then
    echo "please provide docker repository url"
	echo "${BASH_SOURCE[0]} [docker-repo-project-url]"
	echo "ex) ./upload-images.sh harbor.pks-domain.com/greenplum"
	exit
fi

PACKAGE_DIR=.
IMAGE_REPO=$1

GREENPLUM_IMAGE_NAME="${IMAGE_REPO}/greenplum-for-kubernetes:$(cat ./$PACKAGE_DIR/images/greenplum-for-kubernetes-tag)"
docker tag $(cat ./$PACKAGE_DIR/images/greenplum-for-kubernetes-id) ${GREENPLUM_IMAGE_NAME}
docker push ${GREENPLUM_IMAGE_NAME}

OPERATOR_IMAGE_NAME="${IMAGE_REPO}/greenplum-operator:$(cat ./$PACKAGE_DIR/images/greenplum-operator-tag)"
docker tag $(cat ./$PACKAGE_DIR/images/greenplum-operator-id) ${OPERATOR_IMAGE_NAME}
docker push ${OPERATOR_IMAGE_NAME}
```

upload 
```
$ upload-images.sh harbor.pks-domain.com/greenplum

```


### configure private docker repository env

```
$ cd ./greenplum-for-kubernetes-*

vi ./operator/key.json

{ "auths": { "<registry URL>": { "username":"<username>", "password":"<password>" } } }


$ vi workspace/operator-values-overrides.yaml

dockerRegistryKeyJson: key.json
operatorImageRepository: harbor.pks-domain.com/greenplum/greenplum-operator
greenplumImageRepository: harbor.pks-domain.com/greenplum/greenplum-for-kubernetes


$ kubectl create -f ./initialize_helm_rbac.yaml

```

### setup helm

```

$ helm init --wait --service-account tiller --upgrade

$ helm install --name greenplum-operator -f workspace/operator-values-overrides.yaml operator/

$ watch kubectl get all

```


### check status of greenplum-operator
```

$ kubectl logs -l app=greenplum-operator

time="2019-01-10T21:57:35Z" level=info msg="Go Version: go1.11.4"
time="2019-01-10T21:57:35Z" level=info msg="Go OS/Arch: linux/amd64"
time="2019-01-10T21:57:35Z" level=info msg="creating operator"
time="2019-01-10T21:57:35Z" level=info msg="running operator"
time="2019-01-10T21:57:35Z" level=info msg="creating Greenplum CRD"
time="2019-01-10T21:57:35Z" level=info msg="successfully updated greenplum CRD"
time="2019-01-10T21:57:35Z" level=info msg="starting Greenplum InformerFactory"
time="2019-01-10T21:57:35Z" level=info msg="running Greenplum controller"
time="2019-01-10T21:57:35Z" level=info msg="started workers"

```


# troubleshooting

## cleanup helm.

```
$ helm ls --all

NAME              	REVISION	UPDATED                 	STATUS  	CHART         	APP VERSION	NAMESPACE
greenplum-operator	1       	Wed Jun 26 15:16:49 2019	DEPLOYED	operator-1.0.0	v1.2.0     	default
```
delete halm  greenplum-operator

```

$ helm delete --purge greenplum-operator

```
if above delete hang, 

```
$ kubectl get all --show-labels

$ kubectl delete job.batch/pre-delete-greenplum-operator

```
## Pod Security Policy (PSP) 
https://docs.pivotal.io/runtimes/pks/1-4/pod-security-policy.html

```
$ kubectl get events --all-namespaces -w
NAMESPACE    LAST SEEN   TYPE      REASON         KIND         MESSAGE
default      4m9s        Warning   FailedCreate   ReplicaSet   Error creating: pods "greenplum-operator-86b86d8444-" is forbidden: unable to validate against any pod security policy: 

```
solution
1. go to opsman UI> pks tile> plan..
2. setting plan for Allow Priviledged:  greenplum requires priviledged container. check this option.
3. setting plan for Admission plugins:  greenplum requires automatic priviledges. uncheck PodSecurityPolicy, DenyEscalatingExec, SecurityContextDeny option.
4. apply-change in opsman UI.

## self-signed-CA for private-docker-repo

in k8s dashboard, there is error message saying:
```
Failed to pull image “harbor.pksdemo.net/greenplum/greenplum-operator:v1.2.0”: rpc error: code = Unknown desc = Error response from daemon: Get https://harbor.pksdemo.net/v2/: x509: certificate signed by unknown authority
```
solution: to use private docker-registry using self-signed CA, your k8s cluster need to recognize the CA. you need to set the self-signed CA to bosh-director tile in opsmanager before provisioning k8s cluster. see https://docs.pivotal.io/pcf/om/2-0/vsphere/config.html#security-config
https://docs.pivotal.io/pivotalcf/2-5/opsguide/docker-registry.html#ops-man
