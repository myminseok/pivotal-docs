
# Install and setup Healthwatch
WARNING: this docs is for health 1.5, see official document for the latest healthwatch.

- https://docs.pivotal.io/pcf-healthwatch/1-5/index.html
- http://docs.pivotal.io/platform-automation/v2.1/reference/pipeline.html#installing-ops-manager-and-tiles


## Config
- docs: http://docs.pivotal.io/platform-automation/v2.1/reference/inputs-outputs.html
- sample: https://github.com/myminseok/platform-automation-template
```
platform-automation-template
└── dev-1
    ├── products
    │   └── healthwatch.yml
    ├── download-product-configs
    ├── env
    │   └── env.yml             
    ├── generated-config
    ├── state
    └── vars

```
### env.yml
- http://docs.pivotal.io/platform-automation/v2.1/configuration-management/configure-env.html


###  healthwatch.yml

```
1) stage healthwatch on opsmanager.

2) configure the healthwatch via opsmanager UI -> see following guide

3) run 'staged-healthwatch-config' in concourse pipeline( 'om staged-config') to extract healthwatch.yml

```
or use tile-config-generator to get cf.yml template(template only)
- https://github.com/pivotalservices/tile-config-generator



#### Configure healthwatch tile before running 'staged-healthwatch-config'

#####  Healthwatch Component Config
- Redis Worker Count, Ingestor Count: Set to a ratio of one Ingestor for every three Doppler Server instances configured in the PAS tile. If the data being displayed in the PCF Healthwatch UI is regularly delayed by more than one-minute, scale up the number of instances.
- Event Alerts tile (EVA): select to publish events to Event Alerts Tile. All events will still be calculated and stored in the alert table.


##### Health Check > Ops Manager URL: https://opsman.pcfdemo.net

##### Health Check > BOSH Deployment Checker
- create a uaac client in bosh director to see bosh health check tasks.
- guide: https://docs.pivotal.io/pivotalcf/2-3/customizing/opsmanager-create-bosh-client.html

```
1) login to uaac envirionment: ssh into opsmanager VM.

2) $ uaac target https://BOSH-DIRECTOR-IP:8443 --ca-cert /var/tempest/workspaces/default/root_ca_certificate

3). Ops Manager UI > BOSH Director tile > Credentials tab> record value of "Uaa Login Client Credentials" and "Uaa Admin User Credentials".

4) $ uaac token owner get login -s UAA-LOGIN-CLIENT-CREDENTIALS
User name:  admin
Password:  UAA-ADMIN-USER-CREDENTIALS

Successfully fetched token via owner password grant.
Target: https://10.85.16.4:8443
Context: admin, from client login


5) $ uaac client add bosh-admin-for-healthwatch --authorized_grant_types client_credentials \
--authorities bosh.admin --secret <PUT-NEW-SECRET>

6) set the created client and password to UAA Client Name and secret for BOSH Task Check in BOSH Deployment Checker.
```


## Adding using pipeline(automation)
use docker image : pcfnorm/rootfs for uaac


# After installation

## Healthwatch dashboard

```
https://healthwatch.PAS-SYSTEM-DOMAIN

=> id/pass: opsman UI> PAS tile > credentials tab> UAA >  admin credentials

```

#### Monitoring healthwatch itself
https://docs.pivotal.io/pcf-healthwatch/1-5/monitoring.html#key-performance-indicators-for-pcf-healthwatch

#### Monitoring PAS performance 
https://docs.pivotal.io/pcf-healthwatch/1-5/monitoring.html#service-level-indicators-for-pcf-healthwatch



## Healthwatch alert configurations
- https://docs.pivotal.io/pcf-healthwatch/1-5/api/alerts.html

#### Create healthwatch admin user in PAS uaa.
- guide: https://docs.pivotal.io/pcf-healthwatch/1-5/api/alerts.html#prerequisites

```
1) login to uaac envirionment: ssh into opsmanager VM.

2) create uaa client:

uaac target uaa.<PAS-SYSTEM-DOMAIN>

uaac token client get admin -s <UAA-ADMIN-CLIENT-SECRET> 

 => UAA-ADMIN-CLIENT-SECRET: opsman UI> PAS tile > credentials tab> UAA> admin client credentials

uaac client add healthwatch-api-client --authorities "healthwatch.admin" --scope "healthwatch.admin" --authorized_grant_types "client_credentials refresh_token" --secret='<YOUR-PASSWORD>'

3) login to PAS uaa:
uaac target uaa.<PAS-SYSTEM-DOMAIN>
uaac token client get healthwatch-api-client -s '<YOUR-PASSWORD>'
uaac context

4) test:
uaac curl https://healthwatch-api.<PAS-SYSTEM-DOMAIN>/info -k

200 OK
RESPONSE HEADERS:
...
RESPONSE BODY:
HAPI is happy
```

#### Configure alerts rule

```
1) login to uaac envirionment: ssh into opsmanager VM.

2) login to PAS uaa:
uaac target uaa.<PAS-SYSTEM-DOMAIN>
uaac token client get healthwatch-api-client -s '<YOUR-PASSWORD>'
uaac context


3) view alert configuration :
uaac curl https://healthwatch-api.SYSTEM-DOMAIN/v1/alert-configurations  -k 

4) view supported alert list
https://docs.pivotal.io/pcf-healthwatch/1-5/api/alerts.html#defaults

5) view specific alert configuration:

uaac curl -k "https://healthwatch-api.SYSTEM-DOMAIN/v1/alert-configurations?q=origin == 'healthwatch' and name == 'Diego.AvailableFreeChunksDisk'"

200 OK
RESPONSE HEADERS:
[ {
  "query" : "origin == 'healthwatch' and name == 'Diego.AvailableFreeChunksDisk'",
  "threshold" : {
    "critical" : 50.0,
    "warning" : 100.0,
    "type" : "LOWER"
  }
} ]


5) alter specific alert configuration:

uaac curl -k -X POST "https://healthwatch-api.SYSTEM-DOMAIN/v1/alert-configurations" -H "Content-Type: application/json"  --data "{\"query\" : \"origin == 'healthwatch' and name == 'Diego.AvailableFreeChunksDisk'\",    \"threshold\" : {      \"critical\" : 20.0,      \"warning\" : 30.0,     \"type\" : \"LOWER\"  }}"


6) alter other configurations: 
uaac curl -k "https://healthwatch-api.SYSTEM-DOMAIN/v1/alert-configurations?q=origin == 'healthwatch' and name == ‘Diego.AvailableFreeChunks'"

```

