# How to customize agant on tanzu offline java buildpack.

Java Buildpack v4.72.0 and later are commercial versions of the open source Java buildpack described in the java-buildpack repository in the Cloud Foundry GitHub org or (tanzu doc)[https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/elastic-application-runtime/6-0/eart/java-overview.html]

  
This document describes how to add or customize library into tanzu java buildpack as offline by referencing the original KB is here(https://knowledge.broadcom.com/external/article/406683/how-to-add-oracle-jre-to-tpcf-commercial.html)

this will repackage Java buildpack offline v4.85.0 + AppD agent 24.11.0_36469 (from Java buildpack offline v4.80.0)


### Prerequisites
- any linux jumpbox.
- no need to download any resources from internet.

## Procedure

### [Step1] prepare tanzu Java buildpack offline v4.85.0 ONLINE and OFFLINE 
download Java buildpack offline v4.85.0 ONLINE and OFFLINE version from (tanzu portal)[https://support.broadcom.com/group/ecx/productfiles?subFamily=Java%20Buildpack&displayGroup=Java%20Buildpack&release=4.85.0&os=&servicePk=536879&language=EN] (offline version can not download external agent bits) 

unzip files.

```

ubuntu@opsman321:~$ mkdir java-buildpack-offline-v4.80.0
ubuntu@opsman321:~$ unzip java-buildpack-offline-v4.80.0.zip -d java-buildpack-offline-v4.80.0


ubuntu@opsman321:~$ mkdir custom-java-buildpack-v4.85.0-appd-manual  
ubuntu@opsman321:~$ unzip java-buildpack-offline-v4.85.0.zip -d custom-java-buildpack-v4.85.0-appd-manual  

```

### [Step2] Replace AppD agent 24.11.0_36469 cached resources from java-buildpack-offline-v4.80.0

```
ubuntu@opsman321:~$ rm -rf custom-java-buildpack-v4.85.0-appd-manual/resources/cache/7f15506ae439cdd4f66a7c0e124a31562f5ca58987fbba305c6965a0eb4ba8ae*
ubuntu@opsman321:~$ cp -r java-buildpack-offline-v4.80.0/resources/cache/d2b4087d4e8bf4f409d7064af712d8cecd7dd8beecf799017eb7e7f9ae21647a* custom-java-buildpack-v4.85.0-appd-manual/resources/cache/

ubuntu@opsman321:~$ ls -al custom-java-buildpack-v4.85.0-appd-manual/resources/cache/d2b4087d4e8bf4f409d7064af712d8cecd7dd8beecf799017eb7e7f9ae21647a*
-rw-r--r--@ 1 kminseok  staff  51697627  4월 16 09:39 custom-java-buildpack-v4.85.0-appd-manual/resources/cache/d2b4087d4e8bf4f409d7064af712d8cecd7dd8beecf799017eb7e7f9ae21647a.cached
-rw-r--r--@ 1 kminseok  staff        34  4월 16 09:39 custom-java-buildpack-v4.85.0-appd-manual/resources/cache/d2b4087d4e8bf4f409d7064af712d8cecd7dd8beecf799017eb7e7f9ae21647a.etag
-rw-r--r--@ 1 kminseok  staff        29  4월 16 09:39 custom-java-buildpack-v4.85.0-appd-manual/resources/cache/d2b4087d4e8bf4f409d7064af712d8cecd7dd8beecf799017eb7e7f9ae21647a.last_modified
```

### [Step3] re-packaging

```
ubuntu@opsman321:~$ cd custom-java-buildpack-v4.85.0-appd-manual
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd-manual$ zip -r ../custom-java-buildpack-v4.85.0-appd-manual.zip .

```

```
1572101759  4월 16 09:43 custom-java-buildpack-v4.85.0-appd-manual.zip
```

verify contents
```
unzip -l custom-java-buildpack-v4.85.0-appd-manual.zip
```


### [Step4] Test the custom buildpack 

login cf cli as admin.  and upload buildpack to cloudfoundry.

```
cf create-buildpack java_buildpack_offline_485_appd_manual   java-buildpack-offline-v4.85.0-manual.zip 30

cf update-buildpack java_buildpack_offline_485_appd_manual --assign-stack cflinuxfs4
```


create a dummy app-dynamics instance

```
cf cups appdynamics-service -p '{"account-access-key":"xxxx", "account-name":"a", "application-name":"appname", "host-name":"myhost", "plan-description":"standard", "plan-name":"standard", "port":"9999", "ssl-enabled":false}'
```

prepare manifest.yml
```
---
applications:
- name: spring-music-485
  memory: 1G
  random-route: false
  routes:
  - route: spring-music.apps.lab.pcfdemo.net
  path: ./spring-music-mkim-1.0.jar
  buildpacks:
  - java_buildpack_offline_485_appd_manual
  env:
    JBP_CONFIG_OPEN_JDK_JRE: '{ jre: { version: 17.+ } }'
  services:
  - appdynamics-service

```


cf push

```
Packaging files to upload...
Uploading files...
 652.06 KiB / 652.06 KiB [===================================================================================================================================================================================================================] 100.00% 1s

Waiting for API to complete processing files...

Staging app and tracing logs...
   Downloading java_buildpack_offline_485_appd_manual...
   Downloaded java_buildpack_offline_485_appd_manual (1.5G)
   Cell b2ef2ef8-30e7-4339-9a9f-02ac3fc92eb8 creating container for instance 225eaef2-2eaa-4bb4-8bac-8b2618742838
   Security group rules were updated
   Cell b2ef2ef8-30e7-4339-9a9f-02ac3fc92eb8 successfully created container for instance 225eaef2-2eaa-4bb4-8bac-8b2618742838
   Downloading app package...
   Downloaded app package (51.6M)
   -----> Java Buildpack v4.85.0 (offline) | https://github.gwd.broadcom.net/TNZ/java-buildpack#23ed3f3
   -----> Downloading Jvmkill Agent 1.17.0_RELEASE from https://java-buildpack.cloudfoundry.org/jvmkill/jammy/x86_64/jvmkill-1.17.0-RELEASE.so (found in cache)
   -----> Downloading Open Jdk JRE 17.0.16_12 from https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/bellsoft-jre17.0.16%2B12-linux-amd64.tar.gz (found in cache)
   Expanding Open Jdk JRE to .java-buildpack/open_jdk_jre (1.2s)
   JVM DNS caching disabled in lieu of BOSH DNS caching
   -----> Downloading Open JDK Like Memory Calculator 3.13.0_RELEASE from https://java-buildpack.cloudfoundry.org/memory-calculator/jammy/x86_64/memory-calculator-3.13.0-RELEASE.tar.gz (found in cache)
   Loaded Classes: 27237, Threads: 250
   -----> Downloading AppDynamics Agent 24.11.0_36469 from https://storage.googleapis.com/java-buildpack-dependencies/appdynamics/appdynamics-24.11.0-36469.tar.gz (found in cache)
   Expanding AppDynamics Agent to .java-buildpack/app_dynamics_agent (0.5s)
   -----> Downloading Client Certificate Mapper 2.0.1 from https://storage.googleapis.com/java-buildpack-dependencies/client-certificate-mapper/client-certificate-mapper-2.0.1.jar (found in cache)
   -----> Downloading Container Security Provider 1.20.0_RELEASE from https://storage.googleapis.com/java-buildpack-dependencies/container-security-provider/container-security-provider-1.20.0-RELEASE.jar (found in cache)
   [JavaMain]                       WARN  Dependency versions have passed end-of-support date: {"spring-boot - 2.4.0"=>"2023-02-23"}, an operator may prevent staging of this app
   Exit status 0
   Uploading droplet, build artifacts cache...
   Uploading droplet...
   Uploading build artifacts cache...
   Uploaded build artifacts cache (129B)

Waiting for app spring-music-485 to start...

Instances starting...
Instances starting...
Instances starting...
Instances starting...
Instances starting...
Instances starting...
Instances starting...
Instances starting...
Instances starting...

name:              spring-music-485
requested state:   started
routes:            spring-music.apps.lab.pcfdemo.net
last uploaded:     Thu 16 Apr 09:48:57 KST 2026
stack:             cflinuxfs4
buildpacks:
	name                                     version                                                                      detect output   buildpack name
	java_buildpack_offline_485_appd_manual   v4.85.0-offline-https://github.gwd.broadcom.net/TNZ/java-buildpack#23ed3f3   java            java

```



