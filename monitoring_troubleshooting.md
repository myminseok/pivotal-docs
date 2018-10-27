
# 참조 자료
 - [Pivotal Key Performance Indicators](https://docs.pivotal.io/pivotalcf/2-2/monitoring/kpi.html)
 - [Healthwatch](https://docs.pivotal.io/pcf-healthwatch/1-3/)
 - [PCF trouble shooting](https://docs.pivotal.io/pivotalcf/2-2/customizing/troubleshooting-diagnostics.html)
 - [Advanced Troubleshooting with the BOSH CLI](https://docs.pivotal.io/pivotalcf/2-2/customizing/trouble-advanced.html)


```
ssh -i <ssh-key-file> ubuntu@<OPSMAN-URL>

bosh alias-env <MY-ENV> -e <DIRECTOR-IP-ADDRESS> --ca-cert /var/tempest/workspaces/default/root_ca_certificate

bosh -e <MY-ENV> login ( director credentials from OpsMan UI)

# vitals 옵션을 추가해 내부상세 정보조회( cpu, mem, disk 등.. )
bosh -e <MY-ENV> -d cf-xxxxxx vms --vitals

# 인스턴트내의 프로세스 상태 조회
bosh -e <MY-ENV> -d cf-xxxxxx instances --ps

# cell 접근
bosh -e <MY-ENV> -d cf-xxxxxx ssh diego_cell/xxxxxx

# cck 접근
bosh -e <MY-ENV> -d p-redis-xxxxxx cck

# VM 내부에서
sudo -i
monit summary
monit restart [process name]
cd /var/vcap/sys/log/[process name]
tail -f *.log

cd /var/vcap/jobs/[process name]/config

```

# 애플리케이션 서비스 구간별 성능 점검
https://docs.pivotal.io/pivotalcf/2-2/adminguide/troubleshooting_slow_requests.html
