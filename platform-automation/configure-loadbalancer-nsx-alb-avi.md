

## Operations Manager v3.0.34+LTS-T adds support for AVI Load Balancer on vSphere
- [release note](https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-operations-manager/3-0/tanzu-ops-manager/release-notes.html)

Tested on:
- opsman 3.0.37
- TAS tile: v6.0.11
- NSX-ALB: 22.1.7


## How to Integrating

### 1. Configuring Bosh Director 
- [tanzu-ops-manager document](https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-operations-manager/3-0/tanzu-ops-manager/vsphere-config.html)
#### set one of authentication methods
- token: [generating access token from avi controller](https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/avi-load-balancer/avi-load-balancer/30-2/vmware-avi-load-balancer-administration-guide/vmware-nsx-advanced-load-balancer-administration-guide-30-2--ditamap/user-authentication-and-authorization/generate-the-authorization-token.html)
- basic auth for avi which is disabled by default. should [enable from avi controller manually](https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/avi-load-balancer/avi-load-balancer/30-2/vmware-avi-load-balancer-administration-guide/vmware-nsx-advanced-load-balancer-administration-guide-30-2--ditamap/user-authentication-and-authorization/http-basic-auth-for-api-queries.html)

#### Apply director change:
- there is no change on NSX-ALB side
- director is ready to api call on NSX-ALB


### 2. Create VS pool on NSX-ALB controller

#### NSX-ALB > Applications> Pools > create pool
- name: tas-web-pool (any name)
- default server port: 443
- Loadbalancer Algorithm: Round Robin
- Servers: empty (will be added router vms by bosh automatically on creating VM)
- Health Monitor> add: System-TCP. (System-HTTPS doesn't work)
- SSL > SSL Profile: System-Standard

#### NSX-ALB > Applications> VS VIP> create
- name : tas-web-vsvip (any name)
- VIPs> add: Auto-Allocate, V4 only, Network, subnet. and no  need to click add and "save"

#### NSX-ALB > Applications> Virtual Services > create > advanced setup
- name: tas-web (any name)
- VS VIP: tas-web-vsvip (previously created)
- Services: 443(SSL)
- TCP/UDP Profile: System-TCP-Proxy
- Application Profile: System-SSL-Application
- Pool: tas-web-pool( previously created)
- SSL Profile: system-standard
- Advanced tab> Service Engine Group> Default-Group (any group to use)
### 3. Configure loadbalancer on TAS tile
there is no explaination on NSX-ALB on [TAS tile documentation](https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-platform-for-cloud-foundry/6-0/tpcf/configure-lb.html) yet

#### TAS tile > Resource config:
- choose component to set loadbalancer config such as Router, Diego-brain
- AVI LOAD BALANCER CONFIGURATION Pools: tas-web-pool (previously created)
- Logical Load Balancer: do not set.
#### Apply change tas tile:
- bosh director will add vm extension for vms
- bosh director will register the created VM to the NSX-ALB target pool on creating VM only.
