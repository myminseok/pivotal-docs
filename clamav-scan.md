## Clamav
https://www.clamav.net/documents/scanning

### ops manager VM에 ssh로 접속해서 VM에 설치된 clamav process 를 확인합니다.
```
# 예를 들어 pivotal-mysql 
ubuntu@opsman-jumpbox:~$ bosh -d pivotal-mysql-2d4ddb42e9b97f5c9164  instances --ps
Using environment '172.16.0.20' as client 'ops_manager'

Task 2307. Done

Deployment 'pivotal-mysql-2d4ddb42e9b97f5c9164'

Instance                                                     Process               Process State  AZ        IPs
dedicated-mysql-broker/d64fd817-af6a-48b2-8b4c-3e0be476b062  -                     running        kr-pub-b  10.0.4.33
...    
~                                                            clamd                 running        -         -
~                                                            freshclam             running        -         -
~                                                            loggregator_agent     running        -         -
~                                                            service-metrics       running        -         -
```

### pivotal-mysql broker vm에 접속
```
ubuntu@opsman-jumpbox:~$ bosh -d pivotal-mysql-2d4ddb42e9b97f5c9164  ssh dedicated-mysql-broker/d64fd817-af6a-48b2-8b4c-3e0be476b062
```
### root로 전환
```
dedicated-mysql-broker/d64fd817-af6a-48b2-8b4c-3e0be476b062:~$ sudo su
```

### 스캔할 대상 파일 목록 생성
```
dedicated-mysql-broker/d64fd817-af6a-48b2-8b4c-3e0be476b062:/root# cat file
/usr/bin/zipinfo
/usr/bin/xzmore
```

### 강제 스캔
```
dedicated-mysql-broker/d64fd817-af6a-48b2-8b4c-3e0be476b062:/var/vcap/jobs/clamav/bin# /var/vcap/packages/clamav/bin/clamdscan -c /var/vcap/jobs/clamav/clamd.conf -f /root/file
/usr/bin/zipinfo: OK
/usr/bin/xzmore: OK

----------- SCAN SUMMARY -----------
Infected files: 0
Time: 0.002 sec (0 m 0 s)
```
