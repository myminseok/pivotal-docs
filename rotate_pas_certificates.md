참고: 
https://docs.pivotal.io/pivotalcf/2-2/security/pcf-infrastructure/api-cert-rotation.html

```
ssh into ops manager VM.

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

$ curl -k https://<opsman.domain.url>/api/v0/certificate_authorities -H "Authorization: Bearer $TOKEN"
{"certificate_authorities":[{"guid":"xxx","issuer":"Pivotal","created_on":"2018-10-10T05:29:46Z","expires_on":"2022-10-10T05:29:46Z","active":true,
"cert_pem":"-----BEGIN CERTIFICATE-----\n xxxxxxx -----END CERTIFICATE-----\n"}]}
```
