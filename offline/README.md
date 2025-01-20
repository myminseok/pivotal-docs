From my understanding during  the initial kick-off last November, your current vsphere environment is ready for TAS installation.
and here is a final prerequisites and download list for the demo foundation that applied our agreement.
please feel free to ask any questions


# Infra resources for single demo foundation.
vSphere Cluster:
- vCPU cores : 200
- Memory requirements: 512 GB
- Storage requirements: 8 TB (VSAN shared among clusters)
Networks:
- 1 x Infrastructure Network /28 (minimum)
- 1 x Deployment Network /24
NTP Server: Access to NTP Server from the TAS networks
DNS: 2 Wildcard DNS (one for each foundation) that point to your Load Balancer (e.g.  *sandbox.bofa.x, *.sandbox2.bofa.x), for DEMO foundation, this record will point to TAS gorouters VM.
Wildcard TLS Certificates: 2 wildcard TLS Certificates that reference each of the Wildcard DNS records above => we will generate self-signed for demo purpose.
Load Balancers : Load Balancer to route traffic to GoRouters in TAS => for DEMO foundation, will use go router directly for demo purpose.

for General requirements, refer to https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-platform-for-cloud-foundry/4-0/tpcf/requirements.html

# Linux Jump Box VM
Linux Jumpbox deployed to the Infrastructure Network to maintain the TAS platform with access from the bank’s network for Platform Operators.
recommends to Ubuntu Jammy
no internet connection is required.
preferred  to be created in advance
Usage:
- running command for building Windows Stemcell
- running command for injecting windows root fs into Windows tile.
- deploying sample apps to TAS foundation.
Download the following tools to the Linux Jump VM:
- TAS Windows tile (already submitted in the original TAS Software list for EARC)
- Windows Container Image cloudfoundry/windows2016fs:2019.0.165
- WIndows Golang release from https://s3.amazonaws.com/windows2019fs-release/
- apt install zip (Ensure to be installed)
- sha256sum (Ensure to be installed)
- Tanzu imgpkg CLI: https://carvel.dev/imgpkg/
- bosh CLI: (https://github.com/cloudfoundry/bosh-cli/releases)
Download resources for windows tile rootfs injection to the Linux Jump VM :
- imgpkg copy -i cloudfoundry/windows2016fs:2019.0.165 --to-tar /PATH/TO/PERSISTENT_DISK/windowsfs/windows2016fs:2019.0.165.tar
- download https://s3.amazonaws.com/windows2019fs-release/fc5fd197-4d20-4c24-5d12-d57e93a4f8f0
- download script from https://github.com/myminseok/pivotal-docs/blob/master/scripts/inject-tasw4-offline.sh
Download TAS Installation files to the Linux Jump VM: (may download the latest patch version higher than this. ex) 4.0.29 -> 4.0.31)
- VMware Tanzu Operations Manager > 3.0.34+LTS-T
- VMware Tanzu Application Service for VMs > 4.0.29+LTS-T
- Tanzu Application Service CF CLI 8.8.2: The Cloud Foundry cf CLI will be installed on Bank of America developer’s workstations , Jump VM
- VMware Tanzu Application Service for VMs [Windows] > 4.0.29+LTS-T
- Tanzu Application Service for Windows Replicator
- Stemcells (Ubuntu Jammy) > 1.631
- Ubuntu Jammy Stemcell for vSphere 1.631
- app-metrics-2.3.0-build.4.pivotal
- Metric-store-1.6.1.pivotal
- Healthwatch-2.3.1.pivotal
- healthwatch-pas-exporter-2.3.1-build.4.pivotal
- vSphere Stembuild CLI-Linux/Window: Stemcells(Windows) 2019.78 : https://support.broadcom.com/group/ecx/productfiles?subFamily=Stemcells%20(Windows)&displayGroup=Stemcells%20(Windows)&release=2019.78&os=&servicePk=524611&language=EN


## Windows Desktop Jump Box VM for demo foundation.
Windows Jumpbox deployed to Infra Network with  access from the bank’s network for Platform Operators
any Windows version
installed web browser, preferred chrome, firefox.
no internet connection is required.  
Usage:
- provides web browser to access TAS operations manager UI for Platform Operators
- provides web browser to access TAS apps manager UI for Platform Operators
- access to Vcenter UI.
Download resources to Windows Jump Box VM:
- ISO for Windows Server 2019 Core, build number: 17763: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019( Evaluation license can be used for demo purpose. or windows license to be supplied by Bank of America), will be deployed to vcenter cluster as a VM.
- Tanzu Application Service CF CLI 8.8.2: The Cloud Foundry cf CLI will be installed on Bank of America developer’s workstations , Jump VM
- a Sample app for demo purpose: Dotnet framework, Dotnet core, java, etc. (https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-platform-for-cloud-foundry/4-0/tpcf/deploy-apps-deploy-app.html)

## building windows stemcell
we will build the stemcell during the session. for more detail, refer to https://docs.vmware.com/en/VMware-Tanzu-Application-Service/4.0/tas-for-vms/create-vsphere-stemcell-automatically.html

## repackaging TAS windows tile
we will do the task during the session. and will use alternative script(from https://github.com/myminseok/pivotal-docs/blob/master/scripts/inject-tasw4-offline.sh) for fully airgapped env, instead of using "winfs-injector" cli  but refer to the official document for the concept and details here: https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-platform-for-cloud-foundry/4-0/tpcf/installing.html