

# PCF 수동 설치
https://docs.pivotal.io/pivotalcf/2-2/customizing/pcf-aws-manual-config.html

https://github.com/pivotal-cf/pcf-pipelines


# AWS IAM 계정 생성

# AWS 제한(limit) 증설
IAM limit (VM) : 50개
vpc
eip

# aws cli 설치:
[aws cli설치가이드](https://aws.amazon.com/cli/?sc_channel=PS&sc_campaign=acquisition_KR&sc_publisher=google&sc_medium=english_command_line_b&sc_content=aws_cli_p&sc_detail=aws%20cli&sc_category=command_line&sc_segment=211466232633&sc_matchtype=p&sc_Country=KR&s_kwcid=AL!4422!3!211466232633!p!!g!!aws%20cli&ef_id=Wx6C2wAAAJp261dN:20180620131114:s)

```
brew install python@2
pip install --upgrade pip setuptools
pip install awscli

```


# aws cli 동작 확인:

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


