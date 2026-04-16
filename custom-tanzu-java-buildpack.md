# How to customize agant on tanzu offline java buildpack.

Java Buildpack v4.72.0 and later are commercial versions of the open source Java buildpack described in the java-buildpack repository in the Cloud Foundry GitHub org or (tanzu doc)[https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/elastic-application-runtime/6-0/eart/java-overview.html]

  
This document describes how to add or customize library into tanzu java buildpack as offline by referencing the original KB is here(https://knowledge.broadcom.com/external/article/406683/how-to-add-oracle-jre-to-tpcf-commercial.html)

for example,  Java buildpack offline v4.85.0 + AppD agent 24.11.0_36469



## Method1: [custom-tanzu-java-buildpack-WITHOUT-internet access](custom-tanzu-java-buildpack-without-internet.md)
this will repackage Java buildpack offline v4.85.0 with AppD agent 24.11.0_36469 from Java buildpack offline v4.80.0.
### Prerequisites
- any linux jumpbox.
- no need to download any resources from internet.


## Method2: [custom-tanzu-java-buildpack-with-internet access ](custom-tanzu-java-buildpack-with-internet.md)
### Prerequisites
1) prepare a linux jumpbox: this guide will use tanzu opsmanager v3.2.1 as a jumpbox.
  - latest ruby installed 
  - internet accessible  https://rubygems.org/ or equivalent to install bundle

2) download appd agent bits (only for air-gapped env) 
- https://storage.googleapis.com/java-buildpack-dependencies/appdynamics/appdynamics-24.11.0-36469.tar.gz

