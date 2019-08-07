# hands-on architecture
![control plane refrerence architecture](https://docs.pivotal.io/pivotalcf/2-3/plan/images/concourse-multi-zone.png)

## Iaas resources(for hands on)

## shared resource:
- git: 10 projects, total around 10GB for each person
- s3: 10 buckets, total 100GB~ 500GB for each person.

## resources per each person:
```
 - platform control-plane total cpu 47/	mem 68gb/ os disk 472gb/	persist disk 400gb.
 - PAS	total: 	cpu 23/	mem 53gb/	os disk 312gb/	persist disk 401gb
 ------------------------------------------------------
 total cpu 70/	mem 131gb/ os disk 783gb/	persist disk 801gb.
 total private IP :38
 
```

- platform control-plane: 
```
- jumpbox: ubuntu, 2cpu, 4gbmem, os disk 3gb, mount disk 50gb
- oss bosh: 
  director: ubuntu, 2cpu, 4gbmem,os disk 40gb, persist disk 100gb
  compile vm(4cpu, 4gbmem,os disk 16gb) * 4 EA
  
- concourse cluster:
  web 2cpu, 4gbmem, os disk 3gb
  db 2cpu, 4gbmem, os disk 8gb
  worker( 2cpu, 4gbmem,os disk 100gb) * 2EA
   
- PCF ops manager: 1cpu, 8gbmem, os disk 150gb
- PCF bosh:  
  director: 2cpu, 4gbmem,os disk 40gb, persist disk 100gb
  compile vm(4cpu, 4gbmem,os disk 16gb) * 4 EA

------------------------------------------------------
 platform control-plane total cpu 47/	mem 68gb/ os disk 472gb/	persist disk 400gb.
 private IP :16
 
```

- Installing PCF PAS(minimum) :
```
         vCPU	/Ram (GB)	/Disk - ephemeral(GB)	/Disk - Persistence (GB)
	Consul	1	1	8	1
	NATS	1	1	8	0
	FileStorage	1	8	8	100
	Mysql Proxy	1	1	8	0
	MySQL Server	1	8	64	100
	backup Prepare Node	1	1	8	200
	Diego BBS	1	1	8	0
	UAA	1	4	32	0
	Cloud Controller	1	4	32	0
	HAProxy 	1	1	8	0
	Router	1	1	8	0
	Service Discovery controller	1	1	8	0
	MySQL Monitor	1	1	8	0
	Clock Global	1	4	32	0
	Cloud Controller worker	1	1	8	0
	Diego Brain	1	2	8	0
	Loggregator Trafficcontroller	1	1	8	0
	syslog adapter	1	1	8	0
	syslog scheduler	1	1	8	0
	Doppler server	1	1	8	0
	TCP Router	1	1	8	0
	credhub	2	8	16	0
  --------------------------------------------------------
  PAS	total: 	cpu 23/	mem 53gb/	os disk 312gb/	persist disk 401gb
  private IP: 22
```

