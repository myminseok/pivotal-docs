## ssh into opsmanager VM


## ssh into mysql VM in PAS2.3
```
$ bosh deployments

ubuntu@opsmanager-2-3:~$ bosh -d cf-c8399c1d00f7742d47a1 ssh mysql
Using environment '10.10.10.21' as client 'ops_manager'

Using deployment 'cf-c8399c1d00f7742d47a1'
```


## root 로 전환
```
mysql/6c1bbe7d-bb6c-4bbd-a2fb-0f6829ffa097:~$ sudo su
mysql/6c1bbe7d-bb6c-4bbd-a2fb-0f6829ffa097:/var/vcap/bosh_ssh/bosh_576006b6471c450#
```

##  mysql.conf의 위치 파악
```
mysql/6c1bbe7d-bb6c-4bbd-a2fb-0f6829ffa097:/var/vcap/store/pxc-mysql# ps -ef | grep mysql
vcap      6735     1  5 Nov30 ?        22:19:15 mysqld --defaults-file=/var/vcap/jobs/pxc-mysql/config/my.cnf --wsrep-new-cluster
```

## sock위치파악
```
mysql/6c1bbe7d-bb6c-4bbd-a2fb-0f6829ffa097:/var/vcap/store/pxc-mysql# grep sock /var/vcap/jobs/pxc-mysql/config/my.cnf
socket                          = /var/vcap/sys/run/pxc-mysql/mysqld.sock
```

## root password 추출
```
mysql/6c1bbe7d-bb6c-4bbd-a2fb-0f6829ffa097:/var/vcap/store/pxc-mysql# grep root /var/vcap/jobs/pxc-mysql/config/my.cnf
wsrep_sst_auth                  = root:xxxxxxxxx
```

## mysql 접속
```
mysql/6c1bbe7d-bb6c-4bbd-a2fb-0f6829ffa097:/var/vcap/store/pxc-mysql# mysql  -u root -S /var/vcap/sys/run/pxc-mysql/mysqld.sock -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 5076
Server version: 5.7.22-22-29.26-log MySQL Community Server (GPL), wsrep_29.26

Copyright (c) 2009-2018 Percona LLC and/or its affiliates
Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+---------------------+
| Database            |
+---------------------+
| information_schema  |
| app_usage_service   |
| autoscale           |
| ccdb                |
| credhub             |
| diego               |
| locket              |
| metrics_db          |
| monitor             |
| mysql               |
| networkpolicyserver |
| nfsvolume           |
| notifications       |
| performance_schema  |
| routing             |
| silk                |
| sys                 |
| uaa                 |
+---------------------+
18 rows in set (0.05 sec)

mysql> use mysql;

```
