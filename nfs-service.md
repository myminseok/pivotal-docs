

# how to get NFS service instance metadata.

### 1. ssh into ops manager vm

### 2. register DNS record for uaa, credhub 

```
ubuntu@opsmanager-2-9:~$ cat /etc/hosts

172.16.25.101 credhub.service.cf.internal
172.16.25.80 uaa.service.cf.internal
```

### 3. login to TAS uaa.
- guide: https://community.pivotal.io/s/article/how-to-login-and-access-credhub-in-pcf?language=en_US

```
credhub api -s credhub.service.cf.internal:8844 --skip-tls-validation
credhub login --client-name=credhub_admin_client --client-secret=sJ2f0W4eWaEsPrFxavMAV-xAW9qEXiNg


ubuntu@opsmanager-2-9:~$ credhub find 
credentials:
- name: /credhub-clients/29ddfecb-81b8-484c-8f49-fa69fb17abbc
  version_created_at: "2021-06-09T06:35:29Z"
- name: /credhub-service-broker/credhub/f625c3a6-6202-4415-abc4-5a0cdd8f3f0f/credentials
  version_created_at: "2021-06-09T06:26:19Z"
- name: /credhub-service-broker/credhub/e9f95468-1d2f-4215-bcb3-1c6068e70076/cc5b626a-6e37-4b75-a4e9-79ea799bb807
  version_created_at: "2021-06-09T05:54:00Z"
- name: /credhub-service-broker/credhub/e9f95468-1d2f-4215-bcb3-1c6068e70076/credentials
  version_created_at: "2021-06-09T05:39:46Z"
- name: /tanzu-mysql/backups/280cb9d7-c0fc-4006-9971-a5377c2bd2f2_1623196801
  version_created_at: "2021-06-09T00:00:01Z"
- name: /tanzu-mysql/backups/280cb9d7-c0fc-4006-9971-a5377c2bd2f2_1623168000
  version_created_at: "2021-06-08T16:00:01Z"
- name: /tanzu-mysql/backups/280cb9d7-c0fc-4006-9971-a5377c2bd2f2_1623139200
  version_created_at: "2021-06-08T08:00:01Z"
- name: /nfsbroker/ae4bebad-2852-4770-b040-23f96b165640
  version_created_at: "2021-06-08T07:19:09Z"
- name: /c/p.spring-cloud-services-scs-service-broker/37a15060-c98c-461e-95e3-1ccf40448bd6/efd6c6d5-24c3-4f1a-b847-b93fd97e10c5/credentials-json
  version_created_at: "2021-06-07T04:32:45Z"
- name: /c/p.spring-cloud-gateway-service-scg-service-broker/2613a7a0-dd3d-4087-9ba7-2550411ba5a7/9545c65e-6803-4fb1-b3a5-cfd9ba660e4e/credentials-json
  version_created_at: "2021-06-07T02:54:26Z"
- name: /c/p.spring-cloud-gateway-service-scg-service-broker/e088d519-7736-41e8-8d2c-c18ab7c0d6b1/credentials-json
  version_created_at: "2021-06-07T02:22:58Z"
- name: /c/p.spring-cloud-services-scs-mirror-service/93cc44d4-3bcc-4448-bed9-aef5a51347c1/credentials
  version_created_at: "2021-06-04T09:23:47Z"
- name: /c/p.spring-cloud-services-scs-service-broker/18e584e8-c812-4ea8-af95-c15c58d1dbfb/credentials-json
  version_created_at: "2021-06-04T08:11:53Z"
- name: /c/p.spring-cloud-services-scs-mirror-service/39880a72-907c-40ad-945d-4c5476a7addb/credentials
  version_created_at: "2021-06-04T05:54:06Z"
- name: /c/p.spring-cloud-services-scs-service-broker/b8ddfa00-7153-4474-b825-0a633049d122/credentials-json
  version_created_at: "2021-06-03T05:27:31Z"
- name: /c/p.spring-cloud-services-scs-service-broker/62919e20-25ec-448b-9d1b-2fe613b3056e/credentials-json
  version_created_at: "2021-06-03T03:23:32Z"
- name: /nfsbroker/c89372a4-b1ba-4b31-9f27-71fb10615fcf
  version_created_at: "2021-05-28T06:24:59Z"
- name: /nfsbroker/68e9a0b7-13ba-4fa2-b6a7-2736e6c14888
  version_created_at: "2021-05-28T06:23:46Z"
- name: /nfsbroker/c212ef9e-2163-49d0-ac0e-b400732319bf
  version_created_at: "2021-05-27T13:12:28Z"
- name: /nfsbroker/4d2b7964-1cbb-45c5-ad50-22a9b6158ce5
  version_created_at: "2021-05-27T13:12:17Z"
- name: /c/p.spring-cloud-gateway-service-scg-service-broker/client-certificate
  version_created_at: "2021-05-25T10:54:39Z"

```
### 4. fetch nfs service instance record.

```
ubuntu@opsmanager-2-9:~$ credhub get -n /nfsbroker/4d2b7964-1cbb-45c5-ad50-22a9b6158ce5
id: 6cd4852a-6d18-4660-b21a-e01899f1460e
name: /nfsbroker/4d2b7964-1cbb-45c5-ad50-22a9b6158ce5
type: json
value:
  ServiceFingerPrint:
    share: 192.168.150.167/home/ubuntu/nfs
  organization_guid: 2d05355d-6359-4ecc-b80f-50a3eaa2ea62
  plan_id: 09a09260-1df5-4445-9ed7-1ba56dadbbc8
  service_id: 997f8f26-e10c-11e7-80c1-9a214cf093ae
  space_guid: f8d3b300-64c9-450f-9761-0420d1f650b9
version_created_at: "2021-05-27T13:12:17Z"
```
