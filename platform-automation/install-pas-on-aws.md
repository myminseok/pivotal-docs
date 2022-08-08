

# Manually installing PAS guide
https://docs.pivotal.io/ops-manager/2-10/install/aws-manual.html


# AWS IAM 

## EC2 limit quota for TAS
https://docs.pivotal.io/ops-manager/2-10/install/aws.html
```
vpc=> 1+
Elastic LB: 2+  (TAS http, tcp)
Elastic IP: 5+ ( opsman, tas lb, ssh, tcp, sample app)
EC2 VM instance => 
t2.micro: 50
c4.large: 20
m4.large: 20
r4.large: 20

```


# EC2 limit quota for PKS
- VPC 1개: opsman용 (control plane은 기존것 재활용)
- EC2: ops manager: m4 large *1
    bosh director: m4 large *1
    pivotal container service:   m4 large *1
    k8s cluster#1: master: t2.medium *1, worker: t2.medum *1 
    elb: 2개 이상( k8s cluster master VM, 샘플 앺 서비스 노출시?)
    EIP: 2개 이상( opsman, pks api, 샘플 app?)
 https://docs.pivotal.io/runtimes/pks/1-2/aws-requirements.html

2. PKS Api domain: api.pks.domain.com (pivotal container service VM으로 연결)



# aws cli:
[aws cli guide](https://aws.amazon.com/cli/?sc_channel=PS&sc_campaign=acquisition_KR&sc_publisher=google&sc_medium=english_command_line_b&sc_content=aws_cli_p&sc_detail=aws%20cli&sc_category=command_line&sc_segment=211466232633&sc_matchtype=p&sc_Country=KR&s_kwcid=AL!4422!3!211466232633!p!!g!!aws%20cli&ef_id=Wx6C2wAAAJp261dN:20180620131114:s)

```
brew install python@2
pip install --upgrade pip setuptools
pip install awscli

```


# check aws cli:

```
aws ec2 describe-availability-zones 
{
    "AvailabilityZones": [
        {
            "State": "available", 
            "ZoneName": "ap-northeast-2a", 
            "Messages": [], 
            "RegionName": "ap-northeast-2"
        }, 
        {
            "State": "available", 
            "ZoneName": "ap-northeast-2c", 
            "Messages": [], 
            "RegionName": "ap-northeast-2"
        }
    ]
}
```


