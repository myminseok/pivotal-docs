## Maestro compatibility table
- https://docs.pivotal.io/ops-manager/2-10/security/pcf-infrastructure/maestro-tile-compatibility.html
## IF ALL service tiles are compatable with Maestro=> Maestro
- https://docs.pivotal.io/ops-manager/2-10/security/pcf-infrastructure/advanced-certificate-rotation.html#services-rotation 
## Maestro incompatibile(TKGi)=>  Ops Manager API 
- https://docs.pivotal.io/ops-manager/2-10/security/pcf-infrastructure/managing-certificates.html
- service tls ca: https://docs.pivotal.io/ops-manager/2-10/security/pcf-infrastructure/services_tls_ca_rotate.html
## Opsman 2.7-2.8, with Mysql, redis, rabbitmq, gemfire 
- https://community.pivotal.io/s/article/Rotating-services-tls-ca-certificate-using-credhub-transitional-certificate-rotation-feature?language=en_US

## Certs Expired already: 
- How to rotate an already expired /services/tls_ca certificate: https://community.pivotal.io/s/article/How-to-rotate-and-already-expired-services-tls-ca-certificate?language=en_US


### with Ops Manager API 

```
# ssh into ops manager VM.

$ uaac target https://<opsman.domain.url>/uaa --skip-ssl-validation
Target: https://<opsman.domain.url>/uaa
Context: admin, from client opsman

$ uaac token owner get
Client ID:  opsman
Client secret:
User name:  admin
Password:  <opsman ui admin password>

Successfully fetched token via owner password grant.
Context: admin, from client opsman

$ uaac context
[1]*[https://<opsman.domain.url>/uaa]
  skip_ssl_validation: true

  [0]*[admin]
      user_id: 
      client_id: opsman
      access_token: xxxxx.....
      token_type: bearer
      expires_in: 43199
      scope: opsman.admin scim.me uaa.admin clients.admin
      jti: 

$ export TOKEN="<uaac context의 결과에서 access_token을 붙여넣음>"


# ops manager root CA조회
$ curl -k https://<opsman.domain.url>/api/v0/certificate_authorities -H "Authorization: Bearer $TOKEN"
HTTP/1.1 200 OK
{
  "certificate_authorities": [
    {
      "guid": "f7bc18f34f2a7a9403c3",
      "issuer": "Pivotal",
      "created_on": "2017-01-09",
      "expires_on": "2021-01-09",
      "active": true,
      "cert_pem": "-----BEGIN CERTIFICATE-----\nMIIC+zCCAeOgAwIBAgI....etc"
    }
  ]
}

# 만료 예정 인증서 조회
$ curl "https://OPS-MAN-FQDN/api/v0/deployed/certificates?expires_within=6m" \
      -H "Authorization: Bearer YOUR-UAA-ACCESS-TOKEN"
     
     
# ops manager에 새로운  root CA생성
$ curl "https://OPS-MAN-FQDN/api/v0/certificate_authorities/generate" \
  -X POST \
  -H "Authorization: Bearer YOUR-UAA-ACCESS-TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'


# ops manager root CA조회
$ curl -k https://<opsman.domain.url>/api/v0/certificate_authorities -H "Authorization: Bearer $TOKEN"

HTTP/1.1 200 OK
{
  "certificate_authorities": [
    {
      "guid": "f7bc18f34f2a7a9403c3",
      "issuer": "Pivotal",
      "created_on": "2017-01-09",
      "expires_on": "2021-01-09",
      "active": true,
      "cert_pem": "-----BEGIN CERTIFICATE-----\nMIIC+zCCAeOgAwIBAgI....etc"
    }
    {
      "guid": "a8ee01e33e3e3e3303e3",
      "issuer": "Pivotal",
      "created_on": "2017-04-09",
      "expires_on": "2021-04-09",
      "active": false,
      "cert_pem": "-----BEGIN CERTIFICATE-----\zBBBC+eAAAe1gAwAAAeZ....etc"
    }
  ]
}

# Ops Manager UI에 로그인 to https://OPS-MAN-FQDN 

# BOSH Director tile> Config>  Recreate All VMs 체크

# Apply Changes



# 적용 후 ops manager root CA조회
$ curl -k https://<opsman.domain.url>/api/v0/certificate_authorities -H "Authorization: Bearer $TOKEN"

# 만료 예정 인증서 조회
$ curl "https://OPS-MAN-FQDN/api/v0/deployed/certificates?expires_within=6m" \
      -H "Authorization: Bearer YOUR-UAA-ACCESS-TOKEN"
     


  
```
