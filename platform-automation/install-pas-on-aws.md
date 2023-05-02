

# Installing TAS Manually
https://docs.pivotal.io/ops-manager/2-10/install/aws-manual.html

# Prerequisites
#### AWS IAM 
- https://docs.pivotal.io/ops-manager/2-10/aws/required-objects.html
- https://docs.pivotal.io/ops-manager/2-10/aws/prepare-env-manual.html#create-iam
- https://docs.pivotal.io/ops-manager/2-10/install/policy-doc.html
- additonal iam policy: https://docs.pivotal.io/ops-manager/2-10/install/policy-doc.html#add-policies
- route53: https://docs.aws.amazon.com/ko_kr/Route53/latest/DeveloperGuide/access-control-managing-permissions.html

#### EC2 limit quota for TAS
- https://docs.pivotal.io/ops-manager/2-10/install/aws.html
- https://docs.pivotal.io/application-service/2-13/operating/scaling-ert-components.html

```
vpc=> 1+
Elastic LB: 2+  (TAS http, tcp)
Elastic IP: 5+ ( aws NAT, opsman, tas lb, ssh, tcp, sample app)
EC2 VM instance => 
t2.micro: 50
c4.large: 5
m4.large: 5
r4.large: 5
```
```
micro: 15
small: 1
medium.mem: 1+
medium.disk: 2+
large.disk: 1+
large: 1+
xlarge.disk: 1+
```


#### EC2 limit quota for PKS
- VPC 1개: opsman용 (control plane은 기존것 재활용)
- EC2: ops manager: m4 large *1
    bosh director: m4 large *1
    pivotal container service:   m4 large *1
    k8s cluster#1: master: t2.medium *1, worker: t2.medum *1 
    elb: 2개 이상( k8s cluster master VM, 샘플 앺 서비스 노출시?)
    EIP: 2개 이상( opsman, pks api, 샘플 app?)
 https://docs.pivotal.io/runtimes/pks/1-2/aws-requirements.html

2. PKS Api domain: api.pks.domain.com (pivotal container service VM으로 연결)


#### Prepare DNS(hosted zone)
- will host TAS domain records: *.sys.TAS-DOMAIN. *.apps.TAS-DOMAIN. opsman-domain(optional)
- recommends to use Route53

#### aws cli on jumpbox or local PC:
[aws cli guide](https://aws.amazon.com/cli/?sc_channel=PS&sc_campaign=acquisition_KR&sc_publisher=google&sc_medium=english_command_line_b&sc_content=aws_cli_p&sc_detail=aws%20cli&sc_category=command_line&sc_segment=211466232633&sc_matchtype=p&sc_Country=KR&s_kwcid=AL!4422!3!211466232633!p!!g!!aws%20cli&ef_id=Wx6C2wAAAJp261dN:20180620131114:s)

```
brew install python@2
pip install --upgrade pip setuptools
pip install awscli

```
check aws cli:
```
aws ec2 describe-availability-zones 
```


## Install TAS
#### [Terraforming AWS resources](terraforming-aws.md)
#### Provision opsmanager VM
- [Provision opsmanager VM](https://docs.vmware.com/en/VMware-Tanzu-Operations-Manager/2.10/vmware-tanzu-ops-manager/aws-index.html)
- optional - [change IP/PORT of opsman vm](../change-ip-port-opsman.md)
- Opsman UI> director tile> director config: [Include OpsManager Root CA in Trusted Certs](https://docs.vmware.com/en/VMware-Tanzu-Operations-Manager/2.10/vmware-tanzu-ops-manager/vsphere-config.html#step-7-security-pane-7)
#### Configure TAS tile
- [Configure TAS tile - official docs](https://docs.vmware.com/en/VMware-Tanzu-Application-Service/2.13/tas-for-vms/configure-pas.html)
- opsman UI> TAS tile> networking> [Certificates and private keys for the Gorouter and HAProxy> add](https://docs.vmware.com/en/VMware-Tanzu-Application-Service/2.13/tas-for-vms/configure-pas.html#configure-networking-4)
- Certificate Authorities trusted by the Gorouter and HAProxy:
> - [Retrieve the Ops Manager Root CA as a File Through the Ops Manager UI](https://docs.vmware.com/en/VMware-Tanzu-Operations-Manager/2.10/vmware-tanzu-ops-manager/security-pcf-infrastructure-managing-certificates.html#retrieve-the-ops-manager-root-ca-as-a-file-through-the-ops-manager-ui-4) 
> - Paste the opsmanager root CA
- TLS termination point: select `gorouter`
- Gorouter behavior for client certificate validation >  The Gorouter requests but does not require client certificates
#### [Configure TAS tile - AWS ELB](configure-lb-aws.md)
> apply chanage tas tile.

## optional reference) AWS quick start
- https://aws-quickstart.github.io/quickstart-vmware-tanzu-application-platform/
- https://github.com/aws-quickstart/quickstart-vmware-tanzu-application-platform

