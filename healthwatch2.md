## Accessing healthwatch prometheus UI
https://docs.pivotal.io/healthwatch/2-2/troubleshooting.html#missing-router-metrics

### Procedure

#### download mtls cert, key
opsman UI > healthwatch tile > credentials > click tsdb client mtls
```
printf -- "YOUR-KEY" > healthwatch.tsdb.client.key
printf -- "YOUR-CERT" > healthwatch.tsdb.cert.pem
```
#### generate pkcs12 file
put any passphrase to use later on for importing to browser
```
openssl pkcs12 -export -out healthwatch.pfx -inkey healthwatch.tsdb.client.key -in healthwatch.tsdb.cert.pem
```
#### register to firefox
- address text box >  about:config >  proceed at risk > security.osclientcerts.autoreload = true 
- address text box > about:preferences#privacy > cretificate > view certificate...> My Certtificate and load the pfx file to any category

#### register to chrome
- Settings > Manage Certificate > My Certtificate and load the pfx file to any category



#### ssh tunnel to tsdb
```
bosh -d DEPLOYMENT-NAME ssh tsdb/0 --opts='-L PUT_YOUR_OPSMAN_IP:9090:localhost:9090'
```
#### windows PC
c:\Windows\System32\Drivers\etc\hosts file
```
PUT_YOUR_OPSMAN_IP prometheus
```


https://prometheus:9090
