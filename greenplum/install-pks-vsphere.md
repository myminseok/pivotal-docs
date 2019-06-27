
This doc describes how to install PKS api server and provision k8s cluster.

### Prerequisites
https://greenplum-kubernetes.docs.pivotal.io/1-2/prepare-k8s.html
- prepare harbor cluster(airgapped-environment only)
- prepare opsmanager 2.5+ https://network.pivotal.io
- download pks, pks cli, kubectl (https://network.pivotal.io/products/pivotal-container-service/)
- download greenplum-for-kubernetes (https://network.pivotal.io/products/greenplum-for-kubernetes
- prepare DNS server(optional)
- prepare loadbalancer(optional)


### prepare jumpbox ( for mac)

```
## cli tools

brew install jq yq kubernetes-helm docker kubectl

chmod +x pks-darwin-amd64-1.4.0-build.230
sudo mv pks-darwin-amd64-1.4.0-build.230 /usr/local/bin/pks

chmod +x kubectl-darwin-amd64-1.13.5
sudo mv kubectl-darwin-amd64-1.13.5 /usr/local/bin/kubectl
```

### (important, optional) using private docker-registry using self-signed CA
to use private docker-registry using self-signed CA, your k8s cluster need to recognize the CA.
you need to set the self-signed CA to bosh-director tile in opsmanager before provisioning k8s cluster. see https://docs.pivotal.io/pcf/om/2-0/vsphere/config.html#security-config


# Install PKS tile via opsmanager
set pks tile refering to https://docs.pivotal.io/runtimes/pks/1-4/installing-pks-vsphere.html

### configure PKS tile
1. decide pks api server domain, ex) api.my-pksdomain.com. IP will set after installation. and you need to set DNS. 
2. setting plan for Allow Priviledged:  greenplum requires priviledged container. check this option.
3. setting plan for Admission plugins:  greenplum requires automatic priviledges. uncheck PodSecurityPolicy, DenyEscalatingExec, SecurityContextDeny option.

### apply-change in opsmanager

###  setup PKS API Loadbalancer(after pks api installed)
LB will forward port 8443 and 9021 to PKS API VM. https://docs.pivotal.io/runtimes/pks/1-4/installing-pks-vsphere.html#loadbalancer-pks-api
```
forward api.my-pksdomain.com(TCP 8443) -> PKS API VM(TCP 8443)
forward api.my-pksdomain.com(TCP 9021) -> PKS API VM(TCP 9021)
```
#### find pks api server IP: opsman UI> pks tile> status tab.

#### test accessing pks api server
```
$ pks login -a <PKS-API-URL> -u <PKSADMIN> -p <PASSWORD> --skip-ssl-validation
ex) pks login -a api.my-pksdomain.com -u my-pks-admin -p my-secure-password --skip-ssl-validation


$ pks plans

Name    ID                                    Description
small   8A0E21A8-8072-4D80-B365-D1F502085560  Example: This plan will configure a lightweight kubernetes cluster. Not recommended for production workloads.
medium  58375a45-17f7-4291-acf1-455bfdc8e371  Example: This plan will configure a medium sized kubernetes cluster, suitable for more pods.

```

# provisioning K8S cluster

### create K8S cluster

```
$ pks create-cluster my-cluster -e my-cluster.my-pkscluster.com --plan medium

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

```

### setup K8S Loadbalancer
LB will forward port 8443 to K8S master VMs. 
```
forward my-cluster.my-pkscluster.com(TCP 8443) -> K8S master VM(TCP 8443)

```

### access to K8S cluster


### setup kubectl cli
```
$ chmod +x kubectl-darwin-amd64-1.13.5
$ sudo mv kubectl-darwin-amd64-1.13.5 /usr/local/bin/kubectl
```

### get credentials.
```
$ pks get-credentials my-cluster
Fetching credentials for cluster my-cluster.
Context set for cluster my-cluster.
You can now switch between clusters by using:
$kubectl config use-context <cluster-name>
```


### check connection

check and edit "clusters.cluter.server" to point the right url and port to direct k8s masters.

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
CoreDNS is running at https://my-cluster.my-pkscluster:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'

```

Great!, you just install PKS api server and provisioned a k8s cluster!. next  [install greenplum operator for K8S](/greenplum/install-greenplum-operator.md)
