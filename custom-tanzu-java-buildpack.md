# How to customize agant on tanzu offline java buildpack.

Java Buildpack v4.72.0 and later are commercial versions of the open source Java buildpack described in the java-buildpack repository in the Cloud Foundry GitHub org or (tanzu doc)[https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/elastic-application-runtime/6-0/eart/java-overview.html]

  
This document describes how to add or customize library into tanzu java buildpack as offline by referencing the original KB is here(https://knowledge.broadcom.com/external/article/406683/how-to-add-oracle-jre-to-tpcf-commercial.html)

for example,  Java buildpack offline v4.85.0 + AppD agent 24.11.0_36469


## Prerequisites
1) prepare a linux jumpbox: this guild will use tanzu opsmanager v3.2.1 as a jumpbox.
  - latest ruby installed 
  - accessible  https://rubygems.org/ or equivalent to install bundle

2) download appd agent bits (only for air-gapped env) 
- https://storage.googleapis.com/java-buildpack-dependencies/appdynamics/appdynamics-24.11.0-36469.tar.gz

## Procedure
### [Step1] (only for air-gapped env) Prepare a webserver for serving the agent binary internally.

this webserver needs to follow java buildpack metadata format described in (java buildpack Repositories document)[https://github.com/cloudfoundry/java-buildpack/blob/main/docs/extending-repositories.md]

for sample webserver to run on cloudfoundry app, refer to https://github.com/myminseok/webapp-using-nginx-buildpack

```
wget https://storage.googleapis.com/java-buildpack-dependencies/appdynamics/appdynamics-24.11.0-36469.tar.gz
```


after running a app, you should be able to download metadata and related bits.

```
curl https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics/index.yml -k

24.11.0_36469: https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics/appdynamics-24.11.0-36469.tar.gz
```

and can download the bits from internal web server.
```
wget https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics/appdynamics-24.11.0-36469.tar.gz
```


###  [Step2]  [linux jumpbox] Build custom tanzu java buildpack 
this guild will use tanzu opsmanager v3.2.1 as a jumpbox.

download Java buildpack offline v4.85.0 ONLINE version from (tanzu portal)[https://support.broadcom.com/group/ecx/productfiles?subFamily=Java%20Buildpack&displayGroup=Java%20Buildpack&release=4.85.0&os=&servicePk=536879&language=EN] (offline version can not download external agent bits) 

```
ubuntu@opsman321:~$ mkdir custom-java-buildpack-v4.85.0-appd  
ubuntu@opsman321:~$ unzip java-buildpack-v4.85.0.zip -d custom-java-buildpack-v4.85.0-appd
ubuntu@opsman321:~$ cd custom-java-buildpack-v4.85.0-appd
```

and edit ./custom-java-buildpack-v4.85.0-appd/config/app_dynamics_agent.yml

```
---
version: 24.11.0_36469          ## <- pin version
repository_root: "https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics"     #<-= local download location. set any context path in the url. 
default_application_name: $(jq -r -n "$VCAP_APPLICATION | .space_name + \":\" + .application_name
  | @sh")
default_node_name: $(jq -r -n "\"$APPD_CF_NODE_PREFIX\" + ($VCAP_APPLICATION | .application_name)
  + \":$CF_INSTANCE_INDEX\" | @sh")
default_tier_name: 
default_unique_host_name: $(jq -r -n "$VCAP_APPLICATION | .application_id + \":$CF_INSTANCE_INDEX\"
  | @sh")

```

### [Step3] [linux jumpbox] Bundle install 

goto to download and unziped buildpack folder and install bundle.

```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$ sudo bundle install


Don't run Bundler as root. Installing your bundle as root will break this application for all non-root users on this machine.
Bundler 2.7.2 is running, but your lockfile was generated with 2.3.12. Installing Bundler 2.3.12 and restarting using that version.
Fetching gem metadata from https://rubygems.org/.
Fetching bundler 2.3.12
Installing bundler 2.3.12
...
Bundle complete! 10 Gemfile dependencies, 30 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
Post-install message from rubyzip:
RubyZip 3.0 is coming!
**********************

The public API of some Rubyzip classes has been modernized to use named
parameters for optional arguments. Please check your usage of the
following classes:
  * `Zip::File`
  * `Zip::Entry`
  * `Zip::InputStream`
  * `Zip::OutputStream`

Please ensure that your Gemfiles and .gemspecs are suitably restrictive
to avoid an unexpected breakage when 3.0 is released (e.g. ~> 2.3.0).
See https://github.com/rubyzip/rubyzip for details. The Changelog also
lists other enhancements and bugfixes that have been implemented since
version 2.3.0.

```



### [Step4] [linux jumpbox] Bundle exec 

set trust ca certs for internal repo app only if the local repo is running on tanzu platform TAS
```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$ export SSL_CERT_FILE=/var/tempest/workspaces/default/root_ca_certificate
```

goto to download and unziped buildpack folder and run build command.

```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$bundle exec rake clean package OFFLINE=true PINNED=true

...
Caching https://download.run.pivotal.io/your-kit/jammy/x86_64/your-kit-2025.9.191.so
Creating build/java-buildpack-offline-v4.85.0.zip
```

### [Step5] Test the custom buildpack 

login cf cli as admin.  and upload buildpack to cloudfoundry.

```
cf create-buildpack java_buildpack_offline_485_appd   java-buildpack-offline-v4.85.0.zip 30

cf update-buildpack java_buildpack_offline_485_appd --assign-stack cflinuxfs4
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
  - java_buildpack_offline_485_appd
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
   Downloading java_buildpack_offline_485_appd...
   Downloaded java_buildpack_offline_485_appd (1.4G)
   Cell b2ef2ef8-30e7-4339-9a9f-02ac3fc92eb8 creating container for instance 7ed65fba-868b-422c-acf7-3e629dc55245
   Security group rules were updated
   Cell b2ef2ef8-30e7-4339-9a9f-02ac3fc92eb8 successfully created container for instance 7ed65fba-868b-422c-acf7-3e629dc55245
   Downloading app package...
   Downloaded app package (51.6M)
   -----> Java Buildpack v4.85.0 (offline) | https://github.gwd.broadcom.net/TNZ/java-buildpack#23ed3f3
   -----> Downloading Jvmkill Agent 1.17.0_RELEASE from https://java-buildpack.cloudfoundry.org/jvmkill/jammy/x86_64/jvmkill-1.17.0-RELEASE.so (found in cache)
   -----> Downloading Open Jdk JRE 17.0.18_10 from https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/bellsoft-jre17.0.18%2B10-linux-amd64.tar.gz (found in cache)
   Expanding Open Jdk JRE to .java-buildpack/open_jdk_jre (1.2s)
   JVM DNS caching disabled in lieu of BOSH DNS caching
   -----> Downloading Open JDK Like Memory Calculator 3.13.0_RELEASE from https://java-buildpack.cloudfoundry.org/memory-calculator/jammy/x86_64/memory-calculator-3.13.0-RELEASE.tar.gz (found in cache)
   Loaded Classes: 27237, Threads: 250
   -----> Downloading AppDynamics Agent 24.11.0_36469 from https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics/appdynamics-24.11.0-36469.tar.gz (found in cache)
   Expanding AppDynamics Agent to .java-buildpack/app_dynamics_agent (0.4s)
   -----> Downloading Client Certificate Mapper 2.0.1 from https://storage.googleapis.com/java-buildpack-dependencies/client-certificate-mapper/client-certificate-mapper-2.0.1.jar (found in cache)
   -----> Downloading Container Security Provider 1.20.0_RELEASE from https://storage.googleapis.com/java-buildpack-dependencies/container-security-provider/container-security-provider-1.20.0-RELEASE.jar (found in cache)
   [JavaMain]                       WARN  Dependency versions have passed end-of-support date: {"spring-boot - 2.4.0"=>"2023-02-23"}, an operator may prevent staging of this app
   Exit status 0
   Uploading droplet, build artifacts cache...
   Uploading build artifacts cache...
   Uploading droplet...
   Uploaded build artifacts cache (129B)

Waiting for app spring-music-485 to start...

```


## Troubleshooting

### Bundle exec fails to trust local issuer certificate

```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$bundle exec rake clean package OFFLINE=true PINNED=true


[DownloadCache]                  WARN  Unable to download https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics/index.yml into cache build/staging/resources/cache: SSL_connect returned=1 errno=0 peeraddr=192.168.0.70:443 state=error: certificate verify failed (unable to get local issuer certificate)
rake aborted!
```

(solution) set trust ca certs for internal repo app only if the local repo is running on tanzu platform TAS
```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$ export SSL_CERT_FILE=/var/tempest/workspaces/default/root_ca_certificate
```

### Bundle install fails.
```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$ bundle exec rake clean package OFFLINE=true PINNED=true
Could not find rake-13.0.6, redcarpet-3.5.1, rspec-3.11.0, rubocop-1.28.2, rubocop-rspec-2.10.0, rubyzip-2.3.2, tee-1.0.0, terminal-table-3.0.2, webmock-3.14.0, yard-0.9.27, rspec-core-3.11.0, rspec-expectations-3.11.0, rspec-mocks-3.11.1, parallel-1.22.1, parser-3.1.2.0, rainbow-3.1.1, regexp_parser-2.3.1, rexml-3.2.5, rubocop-ast-1.17.0, ruby-progressbar-1.11.0, unicode-display_width-2.1.0, addressable-2.8.0, crack-0.4.5, hashdiff-1.0.1, webrick-1.7.0, rspec-support-3.11.0, diff-lcs-1.5.0, ast-2.4.2, public_suffix-4.0.7 in locally installed gems
Run `bundle install` to install missing gems.
```

==> run as root in jumpbox.
```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$ sudo bundle install
Don't run Bundler as root. Installing your bundle as root will break this application for all non-root users on this machine.
Bundler 2.7.2 is running, but your lockfile was generated with 2.3.12. Installing Bundler 2.3.12 and restarting using that version.
Fetching gem metadata from https://rubygems.org/.
Fetching bundler 2.3.12
Installing bundler 2.3.12
Don't run Bundler as root. Bundler can ask for sudo if it is needed, and installing your bundle as root will break this application for all non-root users on this machine.
Fetching gem metadata from https://rubygems.org/...........
Fetching rake 13.0.6
Installing rake 13.0.6
Using bundler 2.3.12
Fetching public_suffix 4.0.7
Fetching diff-lcs 1.5.0
Fetching ast 2.4.2
Fetching rexml 3.2.5
Installing ast 2.4.2
Installing diff-lcs 1.5.0
Installing rexml 3.2.5
Installing public_suffix 4.0.7
Fetching hashdiff 1.0.1
Installing hashdiff 1.0.1
Fetching parallel 1.22.1
Fetching rainbow 3.1.1
Fetching redcarpet 3.5.1
Fetching regexp_parser 2.3.1
Installing parallel 1.22.1
Installing rainbow 3.1.1
Fetching rspec-support 3.11.0
Installing redcarpet 3.5.1 with native extensions
Installing regexp_parser 2.3.1
Fetching ruby-progressbar 1.11.0
Installing rspec-support 3.11.0
Installing ruby-progressbar 1.11.0
Fetching unicode-display_width 2.1.0
Fetching rubyzip 2.3.2
Installing unicode-display_width 2.1.0
Fetching tee 1.0.0
Installing rubyzip 2.3.2
Fetching webrick 1.7.0
Installing tee 1.0.0
Installing webrick 1.7.0
Fetching parser 3.1.2.0
Fetching addressable 2.8.0
Fetching crack 0.4.5
Installing crack 0.4.5
Installing addressable 2.8.0
Fetching rspec-core 3.11.0
Fetching rspec-expectations 3.11.0
Installing parser 3.1.2.0
Installing rspec-expectations 3.11.0
Installing rspec-core 3.11.0
Fetching rspec-mocks 3.11.1
Installing rspec-mocks 3.11.1
Fetching terminal-table 3.0.2
Fetching yard 0.9.27
Installing terminal-table 3.0.2
Fetching webmock 3.14.0
Fetching rspec 3.11.0
Installing webmock 3.14.0
Installing rspec 3.11.0
Installing yard 0.9.27
Fetching rubocop-ast 1.17.0
Installing rubocop-ast 1.17.0
Fetching rubocop 1.28.2
Installing rubocop 1.28.2
Fetching rubocop-rspec 2.10.0
Installing rubocop-rspec 2.10.0
Bundle complete! 10 Gemfile dependencies, 30 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
Post-install message from rubyzip:
RubyZip 3.0 is coming!
**********************

The public API of some Rubyzip classes has been modernized to use named
parameters for optional arguments. Please check your usage of the
following classes:
  * `Zip::File`
  * `Zip::Entry`
  * `Zip::InputStream`
  * `Zip::OutputStream`

Please ensure that your Gemfiles and .gemspecs are suitably restrictive
to avoid an unexpected breakage when 3.0 is released (e.g. ~> 2.3.0).
See https://github.com/rubyzip/rubyzip for details. The Changelog also
lists other enhancements and bugfixes that have been implemented since
version 2.3.0.
```

### Sample output of bundle exec rake clean package OFFLINE=true PINNED=true

```
ubuntu@opsman321:~/custom-java-buildpack-v4.85.0-appd$ bundle exec rake clean package OFFLINE=true PINNED=true
Pinning spring_boot_efficiency version to 0.5.0
Pinning groovy version to 2.5.23
Pinning spring_boot_cli version to 2.7.18
Pinning Tc Server tc_server-4 version to 4.1.49_RELEASE
Pinning Tc Server tc_server-10 version to 10.1.45_B
Pinning Tc Server tc_server version to 11.0.11_A
Pinning lifecycle_support version to 3.4.0_RELEASE
Pinning logging_support version to 3.4.0_RELEASE
Pinning access_logging_support version to 3.4.0_RELEASE
Pinning redis_store version to 1.3.6_RELEASE
Pinning Tomcat tomcat-10 version to 10.1.54
Pinning Tomcat tomcat version to 9.0.117
Pinning lifecycle_support version to 3.4.0_RELEASE
Pinning logging_support version to 3.4.0_RELEASE
Pinning access_logging_support version to 3.4.0_RELEASE
Pinning redis_store version to 1.3.6_RELEASE
Pinning geode_store version to 2.1.2
Pinning JRE jre-11 version to 11.0.29_12
Pinning JRE jre-11 version to 11.0.29_12
Pinning JRE jre-17 version to 17.0.18_10
Pinning JRE jre-17 version to 17.0.18_10
Pinning JRE jre-21 version to 21.0.10_10
Pinning JRE jre-21 version to 21.0.10_10
Pinning JRE jre-25 version to 25.0.2_12
Pinning JRE jre-25 version to 25.0.2_12
Pinning JRE jre version to 1.8.0_482
Pinning JRE jre version to 1.8.0_482
Pinning jvmkill_agent version to 1.17.0_RELEASE
Pinning jvmkill_agent version to 1.17.0_RELEASE
Pinning memory_calculator version to 3.13.0_RELEASE
Pinning memory_calculator version to 3.13.0_RELEASE
Pinning app_dynamics_agent version to 24.11.0_36469
Pinning azure_application_insights_agent version to 3.7.8
Pinning client_certificate_mapper version to 2.0.1
Pinning container_customizer version to 2.6.0_RELEASE
Pinning container_security_provider version to 1.20.0_RELEASE
Pinning contrast_security_agent version to 6.27.0
[VersionResolver]                WARN  Discarding illegal version 1.28.0-RC2: Invalid micro version '0-RC2'
[VersionResolver]                WARN  Discarding illegal version 1.28.0-RC3: Invalid micro version '0-RC3'
Pinning datadog_javaagent version to 1.61.0
Pinning elastic_apm_agent version to 1.55.5
Pinning google_stackdriver_profiler version to 0.1.0
Pinning google_stackdriver_profiler version to 0.1.0
[VersionResolver]                WARN  Discarding illegal version 25.7.1.21: Invalid micro version '1.21'
[VersionResolver]                WARN  Discarding illegal version 25.2.1.25: Invalid micro version '1.25'
[VersionResolver]                WARN  Discarding illegal version 25.1.1.25: Invalid micro version '1.25'
Pinning introscope_agent version to 25.10.1_10
Pinning jacoco_agent version to 0.8.14
Pinning java_cf_env version to 3.5.1
Pinning agent version to 0.5.0
Pinning clean_up version to 0.1.0
Pinning jprofiler_profiler version to 15.0.4
Pinning jrebel_agent version to 2026.2.0
Pinning luna_security_provider version to 7.4.0
Pinning maria_db_jdbc version to 2.7.9
Pinning metric_writer version to 3.5.0_RELEASE
Pinning new_relic_agent version to 9.2.0
Pinning open_telemetry_javaagent version to 2.26.1
Pinning postgresql_jdbc version to 42.7.10
Pinning riverbed_appinternals_agent version to 11.8.5_BL527
Pinning sealights_agent version to 4.0.2570
Pinning spring_auto_reconfiguration version to 2.12.0_RELEASE
Pinning splunk_otel_java_agent version to 2.26.1
Pinning sky_walking_agent version to 9.6.0
Pinning your_kit_profiler version to 2025.9.191
Pinning your_kit_profiler version to 2025.9.191
Pinning takipi_agent version to 4.84.0
Pinning ruby version to 3.2.8
Caching https://storage.googleapis.com/java-buildpack-dependencies/spring-kit-cli/index.yml
mkdir -p build/staging
Caching https://storage.googleapis.com/java-buildpack-dependencies/groovy/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/spring-boot-cli/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tc-server/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-lifecycle-support/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-logging-support/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-access-logging-support/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/redis-store/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tc-server/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tc-server/index.yml
Caching https://java-buildpack-tomcat-gemfire-store.s3-us-west-2.amazonaws.com/index.yml
cp NOTICE build/staging/NOTICE
chmod 644 build/staging/NOTICE
cp LICENSE build/staging/LICENSE
chmod 644 build/staging/LICENSE
mkdir -p build/staging/resources/tomcat/conf
cp resources/tomcat/conf/server.xml build/staging/resources/tomcat/conf/server.xml
chmod 644 build/staging/resources/tomcat/conf/server.xml
cp resources/tomcat/conf/logging.properties build/staging/resources/tomcat/conf/logging.properties
chmod 644 build/staging/resources/tomcat/conf/logging.properties
cp resources/tomcat/conf/context.xml build/staging/resources/tomcat/conf/context.xml
chmod 644 build/staging/resources/tomcat/conf/context.xml
mkdir -p build/staging/resources/tc_server/templates/user-template/conf
cp resources/tc_server/templates/user-template/conf/server.xml build/staging/resources/tc_server/templates/user-template/conf/server.xml
chmod 644 build/staging/resources/tc_server/templates/user-template/conf/server.xml
cp resources/tc_server/templates/user-template/conf/logging.properties build/staging/resources/tc_server/templates/user-template/conf/logging.properties
chmod 644 build/staging/resources/tc_server/templates/user-template/conf/logging.properties
cp resources/tc_server/templates/user-template/conf/context.xml build/staging/resources/tc_server/templates/user-template/conf/context.xml
chmod 644 build/staging/resources/tc_server/templates/user-template/conf/context.xml
mkdir -p build/staging/resources/tc_server/templates/symbolic-links-template/conf
cp resources/tc_server/templates/symbolic-links-template/conf/context-fragment.xml build/staging/resources/tc_server/templates/symbolic-links-template/conf/context-fragment.xml
chmod 644 build/staging/resources/tc_server/templates/symbolic-links-template/conf/context-fragment.xml
mkdir -p build/staging/resources/tc_server/templates/remote-ip-valve-template/conf
cp resources/tc_server/templates/remote-ip-valve-template/conf/server-fragment.xml build/staging/resources/tc_server/templates/remote-ip-valve-template/conf/server-fragment.xml
chmod 644 build/staging/resources/tc_server/templates/remote-ip-valve-template/conf/server-fragment.xml
mkdir -p build/staging/resources/tc_server/templates/buildpack-support-template/conf
cp resources/tc_server/templates/buildpack-support-template/conf/server-fragment.xml build/staging/resources/tc_server/templates/buildpack-support-template/conf/server-fragment.xml
chmod 644 build/staging/resources/tc_server/templates/buildpack-support-template/conf/server-fragment.xml
cp resources/tc_server/templates/buildpack-support-template/conf/logging.properties build/staging/resources/tc_server/templates/buildpack-support-template/conf/logging.properties
chmod 644 build/staging/resources/tc_server/templates/buildpack-support-template/conf/logging.properties
mkdir -p build/staging/resources/tc_server/conf
cp resources/tc_server/conf/server.xml build/staging/resources/tc_server/conf/server.xml
chmod 644 build/staging/resources/tc_server/conf/server.xml
cp resources/tc_server/conf/logging.properties build/staging/resources/tc_server/conf/logging.properties
chmod 644 build/staging/resources/tc_server/conf/logging.properties
cp resources/tc_server/conf/context.xml build/staging/resources/tc_server/conf/context.xml
chmod 644 build/staging/resources/tc_server/conf/context.xml
mkdir -p build/staging/resources/protect_app_security_provider
cp resources/protect_app_security_provider/IngrianNAE.properties build/staging/resources/protect_app_security_provider/IngrianNAE.properties
chmod 644 build/staging/resources/protect_app_security_provider/IngrianNAE.properties
mkdir -p build/staging/resources/new_relic_agent
cp resources/new_relic_agent/newrelic.yml build/staging/resources/new_relic_agent/newrelic.yml
chmod 644 build/staging/resources/new_relic_agent/newrelic.yml
mkdir -p build/staging/resources/luna_security_provider
cp resources/luna_security_provider/Chrystoki.conf build/staging/resources/luna_security_provider/Chrystoki.conf
chmod 644 build/staging/resources/luna_security_provider/Chrystoki.conf
mkdir -p build/staging/resources/java_main
cp resources/java_main/spring-generations.json build/staging/resources/java_main/spring-generations.json
chmod 644 build/staging/resources/java_main/spring-generations.json
cp resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.last_modified build/staging/resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.last_modified
chmod 644 build/staging/resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.last_modified
cp resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.etag build/staging/resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.etag
chmod 644 build/staging/resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.etag
cp resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.cached build/staging/resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.cached
chmod 644 build/staging/resources/cache/fbb3063ea0b845940ec4423bb163e58b193938b29319ad170bfef5c2fdd09c0c.cached
cp resources/cache/6fc34a998e5bd8320c27ec462776cc7e26e740f8fc5f24872e7a253bcd2aa2e2.cached build/staging/resources/cache/6fc34a998e5bd8320c27ec462776cc7e26e740f8fc5f24872e7a253bcd2aa2e2.cached
Caching https://storage.googleapis.com/java-buildpack-dependencies/redis-store/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/index.yml
chmod 644 build/staging/resources/cache/6fc34a998e5bd8320c27ec462776cc7e26e740f8fc5f24872e7a253bcd2aa2e2.cached
cp resources/cache/6dfebc39a307d640322f73cfb52f7c75a75c8ea0ae71969a5c8ba3c1874cdefb.cached build/staging/resources/cache/6dfebc39a307d640322f73cfb52f7c75a75c8ea0ae71969a5c8ba3c1874cdefb.cached
chmod 644 build/staging/resources/cache/6dfebc39a307d640322f73cfb52f7c75a75c8ea0ae71969a5c8ba3c1874cdefb.cached
cp resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.last_modified build/staging/resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.last_modified
chmod 644 build/staging/resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.last_modified
cp resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.etag build/staging/resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.etag
chmod 644 build/staging/resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.etag
cp resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.cached build/staging/resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.cached
chmod 644 build/staging/resources/cache/62ef28daad7e69d4a8399d15d2f4585639134648321a178f8bea1773fcc64171.cached
cp resources/cache/4898f5ace217f6342958e7eb6bcaa4732a1e1dba5ce7e1aa3f29ef9e45dcb821.cached build/staging/resources/cache/4898f5ace217f6342958e7eb6bcaa4732a1e1dba5ce7e1aa3f29ef9e45dcb821.cached
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/jvmkill/bionic/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-lifecycle-support/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/jvmkill/jammy/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-logging-support/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/memory-calculator/bionic/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-access-logging-support/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/memory-calculator/jammy/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat/index.yml
Caching https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/azure-application-insights/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/client-certificate-mapper/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/container-customizer/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/container-security-provider/index.yml
chmod 644 build/staging/resources/cache/4898f5ace217f6342958e7eb6bcaa4732a1e1dba5ce7e1aa3f29ef9e45dcb821.cached
cp resources/cache/072e6a53de47d560256e944b199ea2ca16122f71cbb04b4c28e3fd4bdcfe4741.cached build/staging/resources/cache/072e6a53de47d560256e944b199ea2ca16122f71cbb04b4c28e3fd4bdcfe4741.cached
Caching https://download.run.pivotal.io/contrast-security/index.yml
Caching https://raw.githubusercontent.com/datadog/dd-trace-java/cloudfoundry/index.yml
chmod 644 build/staging/resources/cache/072e6a53de47d560256e944b199ea2ca16122f71cbb04b4c28e3fd4bdcfe4741.cached
mkdir -p build/staging/resources/azure_application_insights_agent
cp resources/azure_application_insights_agent/AI-Agent.xml build/staging/resources/azure_application_insights_agent/AI-Agent.xml
chmod 644 build/staging/resources/azure_application_insights_agent/AI-Agent.xml
mkdir -p build/staging/resources/app_dynamics_agent/defaults/conf
cp resources/app_dynamics_agent/defaults/conf/app-agent-config.xml build/staging/resources/app_dynamics_agent/defaults/conf/app-agent-config.xml
chmod 644 build/staging/resources/app_dynamics_agent/defaults/conf/app-agent-config.xml
mkdir -p build/staging/lib
cp lib/java_buildpack.rb build/staging/lib/java_buildpack.rb
chmod 644 build/staging/lib/java_buildpack.rb
mkdir -p build/staging/lib/java_buildpack
cp lib/java_buildpack/util.rb build/staging/lib/java_buildpack/util.rb
chmod 644 build/staging/lib/java_buildpack/util.rb
mkdir -p build/staging/lib/java_buildpack/util
cp lib/java_buildpack/util/tokenized_version.rb build/staging/lib/java_buildpack/util/tokenized_version.rb
chmod 644 build/staging/lib/java_buildpack/util/tokenized_version.rb
cp lib/java_buildpack/util/to_b.rb build/staging/lib/java_buildpack/util/to_b.rb
chmod 644 build/staging/lib/java_buildpack/util/to_b.rb
cp lib/java_buildpack/util/start_script.rb build/staging/lib/java_buildpack/util/start_script.rb
chmod 644 build/staging/lib/java_buildpack/util/start_script.rb
cp lib/java_buildpack/util/spring_boot_utils.rb build/staging/lib/java_buildpack/util/spring_boot_utils.rb
chmod 644 build/staging/lib/java_buildpack/util/spring_boot_utils.rb
Caching https://raw.githubusercontent.com/elastic/apm-agent-java/master/cloudfoundry/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/google-stackdriver-profiler/bionic/x86_64/index.yml
cp lib/java_buildpack/util/space_case.rb build/staging/lib/java_buildpack/util/space_case.rb
chmod 644 build/staging/lib/java_buildpack/util/space_case.rb
cp lib/java_buildpack/util/snake_case.rb build/staging/lib/java_buildpack/util/snake_case.rb
chmod 644 build/staging/lib/java_buildpack/util/snake_case.rb
cp lib/java_buildpack/util/shell.rb build/staging/lib/java_buildpack/util/shell.rb
chmod 644 build/staging/lib/java_buildpack/util/shell.rb
cp lib/java_buildpack/util/sanitizer.rb build/staging/lib/java_buildpack/util/sanitizer.rb
chmod 644 build/staging/lib/java_buildpack/util/sanitizer.rb
cp lib/java_buildpack/util/ratpack_utils.rb build/staging/lib/java_buildpack/util/ratpack_utils.rb
chmod 644 build/staging/lib/java_buildpack/util/ratpack_utils.rb
cp lib/java_buildpack/util/qualify_path.rb build/staging/lib/java_buildpack/util/qualify_path.rb
chmod 644 build/staging/lib/java_buildpack/util/qualify_path.rb
cp lib/java_buildpack/util/properties.rb build/staging/lib/java_buildpack/util/properties.rb
chmod 644 build/staging/lib/java_buildpack/util/properties.rb
cp lib/java_buildpack/util/play.rb build/staging/lib/java_buildpack/util/play.rb
chmod 644 build/staging/lib/java_buildpack/util/play.rb
mkdir -p build/staging/lib/java_buildpack/util/play
cp lib/java_buildpack/util/play/pre22_staged.rb build/staging/lib/java_buildpack/util/play/pre22_staged.rb
chmod 644 build/staging/lib/java_buildpack/util/play/pre22_staged.rb
cp lib/java_buildpack/util/play/pre22_dist.rb build/staging/lib/java_buildpack/util/play/pre22_dist.rb
chmod 644 build/staging/lib/java_buildpack/util/play/pre22_dist.rb
cp lib/java_buildpack/util/play/pre22.rb build/staging/lib/java_buildpack/util/play/pre22.rb
chmod 644 build/staging/lib/java_buildpack/util/play/pre22.rb
cp lib/java_buildpack/util/play/post22_staged.rb build/staging/lib/java_buildpack/util/play/post22_staged.rb
chmod 644 build/staging/lib/java_buildpack/util/play/post22_staged.rb
cp lib/java_buildpack/util/play/post22_dist.rb build/staging/lib/java_buildpack/util/play/post22_dist.rb
chmod 644 build/staging/lib/java_buildpack/util/play/post22_dist.rb
cp lib/java_buildpack/util/play/post22.rb build/staging/lib/java_buildpack/util/play/post22.rb
chmod 644 build/staging/lib/java_buildpack/util/play/post22.rb
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/index.yml
cp lib/java_buildpack/util/play/factory.rb build/staging/lib/java_buildpack/util/play/factory.rb
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/index.yml
chmod 644 build/staging/lib/java_buildpack/util/play/factory.rb
Caching https://storage.googleapis.com/java-buildpack-dependencies/google-stackdriver-profiler/jammy/x86_64/index.yml
cp lib/java_buildpack/util/play/base.rb build/staging/lib/java_buildpack/util/play/base.rb
chmod 644 build/staging/lib/java_buildpack/util/play/base.rb
cp lib/java_buildpack/util/java_main_utils.rb build/staging/lib/java_buildpack/util/java_main_utils.rb
chmod 644 build/staging/lib/java_buildpack/util/java_main_utils.rb
cp lib/java_buildpack/util/jar_finder.rb build/staging/lib/java_buildpack/util/jar_finder.rb
chmod 644 build/staging/lib/java_buildpack/util/jar_finder.rb
cp lib/java_buildpack/util/groovy_utils.rb build/staging/lib/java_buildpack/util/groovy_utils.rb
chmod 644 build/staging/lib/java_buildpack/util/groovy_utils.rb
cp lib/java_buildpack/util/format_duration.rb build/staging/lib/java_buildpack/util/format_duration.rb
chmod 644 build/staging/lib/java_buildpack/util/format_duration.rb
cp lib/java_buildpack/util/find_single_directory.rb build/staging/lib/java_buildpack/util/find_single_directory.rb
chmod 644 build/staging/lib/java_buildpack/util/find_single_directory.rb
cp lib/java_buildpack/util/filtering_pathname.rb build/staging/lib/java_buildpack/util/filtering_pathname.rb
chmod 644 build/staging/lib/java_buildpack/util/filtering_pathname.rb
cp lib/java_buildpack/util/file_enumerable.rb build/staging/lib/java_buildpack/util/file_enumerable.rb
chmod 644 build/staging/lib/java_buildpack/util/file_enumerable.rb
cp lib/java_buildpack/util/external_config.rb build/staging/lib/java_buildpack/util/external_config.rb
chmod 644 build/staging/lib/java_buildpack/util/external_config.rb
cp lib/java_buildpack/util/dash_case.rb build/staging/lib/java_buildpack/util/dash_case.rb
chmod 644 build/staging/lib/java_buildpack/util/dash_case.rb
cp lib/java_buildpack/util/constantize.rb build/staging/lib/java_buildpack/util/constantize.rb
chmod 644 build/staging/lib/java_buildpack/util/constantize.rb
cp lib/java_buildpack/util/configuration_utils.rb build/staging/lib/java_buildpack/util/configuration_utils.rb
chmod 644 build/staging/lib/java_buildpack/util/configuration_utils.rb
cp lib/java_buildpack/util/colorize.rb build/staging/lib/java_buildpack/util/colorize.rb
chmod 644 build/staging/lib/java_buildpack/util/colorize.rb
cp lib/java_buildpack/util/class_file_utils.rb build/staging/lib/java_buildpack/util/class_file_utils.rb
chmod 644 build/staging/lib/java_buildpack/util/class_file_utils.rb
cp lib/java_buildpack/util/cache.rb build/staging/lib/java_buildpack/util/cache.rb
chmod 644 build/staging/lib/java_buildpack/util/cache.rb
mkdir -p build/staging/lib/java_buildpack/util/cache
cp lib/java_buildpack/util/cache/internet_availability.rb build/staging/lib/java_buildpack/util/cache/internet_availability.rb
chmod 644 build/staging/lib/java_buildpack/util/cache/internet_availability.rb
cp lib/java_buildpack/util/cache/inferred_network_failure.rb build/staging/lib/java_buildpack/util/cache/inferred_network_failure.rb
chmod 644 build/staging/lib/java_buildpack/util/cache/inferred_network_failure.rb
cp lib/java_buildpack/util/cache/download_cache.rb build/staging/lib/java_buildpack/util/cache/download_cache.rb
chmod 644 build/staging/lib/java_buildpack/util/cache/download_cache.rb
cp lib/java_buildpack/util/cache/cached_file.rb build/staging/lib/java_buildpack/util/cache/cached_file.rb
chmod 644 build/staging/lib/java_buildpack/util/cache/cached_file.rb
cp lib/java_buildpack/util/cache/cache_factory.rb build/staging/lib/java_buildpack/util/cache/cache_factory.rb
chmod 644 build/staging/lib/java_buildpack/util/cache/cache_factory.rb
cp lib/java_buildpack/util/cache/application_cache.rb build/staging/lib/java_buildpack/util/cache/application_cache.rb
chmod 644 build/staging/lib/java_buildpack/util/cache/application_cache.rb
cp lib/java_buildpack/repository.rb build/staging/lib/java_buildpack/repository.rb
chmod 644 build/staging/lib/java_buildpack/repository.rb
mkdir -p build/staging/lib/java_buildpack/repository
cp lib/java_buildpack/repository/version_resolver.rb build/staging/lib/java_buildpack/repository/version_resolver.rb
chmod 644 build/staging/lib/java_buildpack/repository/version_resolver.rb
cp lib/java_buildpack/repository/repository_index.rb build/staging/lib/java_buildpack/repository/repository_index.rb
chmod 644 build/staging/lib/java_buildpack/repository/repository_index.rb
cp lib/java_buildpack/repository/configured_item.rb build/staging/lib/java_buildpack/repository/configured_item.rb
chmod 644 build/staging/lib/java_buildpack/repository/configured_item.rb
cp lib/java_buildpack/logging.rb build/staging/lib/java_buildpack/logging.rb
chmod 644 build/staging/lib/java_buildpack/logging.rb
mkdir -p build/staging/lib/java_buildpack/logging
cp lib/java_buildpack/logging/logger_factory.rb build/staging/lib/java_buildpack/logging/logger_factory.rb
chmod 644 build/staging/lib/java_buildpack/logging/logger_factory.rb
cp lib/java_buildpack/logging/delegating_logger.rb build/staging/lib/java_buildpack/logging/delegating_logger.rb
chmod 644 build/staging/lib/java_buildpack/logging/delegating_logger.rb
cp lib/java_buildpack/jre.rb build/staging/lib/java_buildpack/jre.rb
chmod 644 build/staging/lib/java_buildpack/jre.rb
mkdir -p build/staging/lib/java_buildpack/jre
cp lib/java_buildpack/jre/zulu_jre.rb build/staging/lib/java_buildpack/jre/zulu_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/zulu_jre.rb
cp lib/java_buildpack/jre/zing_jre.rb build/staging/lib/java_buildpack/jre/zing_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/zing_jre.rb
cp lib/java_buildpack/jre/sap_machine_jre.rb build/staging/lib/java_buildpack/jre/sap_machine_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/sap_machine_jre.rb
cp lib/java_buildpack/jre/oracle_jre.rb build/staging/lib/java_buildpack/jre/oracle_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/oracle_jre.rb
cp lib/java_buildpack/jre/open_jdk_like_security_providers.rb build/staging/lib/java_buildpack/jre/open_jdk_like_security_providers.rb
chmod 644 build/staging/lib/java_buildpack/jre/open_jdk_like_security_providers.rb
cp lib/java_buildpack/jre/open_jdk_like_memory_calculator.rb build/staging/lib/java_buildpack/jre/open_jdk_like_memory_calculator.rb
chmod 644 build/staging/lib/java_buildpack/jre/open_jdk_like_memory_calculator.rb
cp lib/java_buildpack/jre/open_jdk_like_jre.rb build/staging/lib/java_buildpack/jre/open_jdk_like_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/open_jdk_like_jre.rb
cp lib/java_buildpack/jre/open_jdk_like.rb build/staging/lib/java_buildpack/jre/open_jdk_like.rb
chmod 644 build/staging/lib/java_buildpack/jre/open_jdk_like.rb
cp lib/java_buildpack/jre/open_jdk_jre.rb build/staging/lib/java_buildpack/jre/open_jdk_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/open_jdk_jre.rb
cp lib/java_buildpack/jre/jvmkill_agent.rb build/staging/lib/java_buildpack/jre/jvmkill_agent.rb
chmod 644 build/staging/lib/java_buildpack/jre/jvmkill_agent.rb
cp lib/java_buildpack/jre/ibm_jre_initializer.rb build/staging/lib/java_buildpack/jre/ibm_jre_initializer.rb
chmod 644 build/staging/lib/java_buildpack/jre/ibm_jre_initializer.rb
cp lib/java_buildpack/jre/ibm_jre.rb build/staging/lib/java_buildpack/jre/ibm_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/ibm_jre.rb
cp lib/java_buildpack/jre/graal_vm_jre.rb build/staging/lib/java_buildpack/jre/graal_vm_jre.rb
chmod 644 build/staging/lib/java_buildpack/jre/graal_vm_jre.rb
cp lib/java_buildpack/framework.rb build/staging/lib/java_buildpack/framework.rb
chmod 644 build/staging/lib/java_buildpack/framework.rb
mkdir -p build/staging/lib/java_buildpack/framework
cp lib/java_buildpack/framework/your_kit_profiler.rb build/staging/lib/java_buildpack/framework/your_kit_profiler.rb
chmod 644 build/staging/lib/java_buildpack/framework/your_kit_profiler.rb
cp lib/java_buildpack/framework/takipi_agent.rb build/staging/lib/java_buildpack/framework/takipi_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/takipi_agent.rb
cp lib/java_buildpack/framework/spring_insight.rb build/staging/lib/java_buildpack/framework/spring_insight.rb
chmod 644 build/staging/lib/java_buildpack/framework/spring_insight.rb
cp lib/java_buildpack/framework/spring_boot_efficiency.rb build/staging/lib/java_buildpack/framework/spring_boot_efficiency.rb
chmod 644 build/staging/lib/java_buildpack/framework/spring_boot_efficiency.rb
cp lib/java_buildpack/framework/spring_auto_reconfiguration.rb build/staging/lib/java_buildpack/framework/spring_auto_reconfiguration.rb
chmod 644 build/staging/lib/java_buildpack/framework/spring_auto_reconfiguration.rb
cp lib/java_buildpack/framework/splunk_otel_java_agent.rb build/staging/lib/java_buildpack/framework/splunk_otel_java_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/splunk_otel_java_agent.rb
cp lib/java_buildpack/framework/sky_walking_agent.rb build/staging/lib/java_buildpack/framework/sky_walking_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/sky_walking_agent.rb
cp lib/java_buildpack/framework/seeker_security_provider.rb build/staging/lib/java_buildpack/framework/seeker_security_provider.rb
Caching https://packages.broadcom.com/artifactory/apm-agents/index.yml
chmod 644 build/staging/lib/java_buildpack/framework/seeker_security_provider.rb
cp lib/java_buildpack/framework/sealights_agent.rb build/staging/lib/java_buildpack/framework/sealights_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/sealights_agent.rb
cp lib/java_buildpack/framework/riverbed_appinternals_agent.rb build/staging/lib/java_buildpack/framework/riverbed_appinternals_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/riverbed_appinternals_agent.rb
cp lib/java_buildpack/framework/protect_app_security_provider.rb build/staging/lib/java_buildpack/framework/protect_app_security_provider.rb
chmod 644 build/staging/lib/java_buildpack/framework/protect_app_security_provider.rb
cp lib/java_buildpack/framework/postgresql_jdbc.rb build/staging/lib/java_buildpack/framework/postgresql_jdbc.rb
chmod 644 build/staging/lib/java_buildpack/framework/postgresql_jdbc.rb
cp lib/java_buildpack/framework/open_telemetry_javaagent.rb build/staging/lib/java_buildpack/framework/open_telemetry_javaagent.rb
chmod 644 build/staging/lib/java_buildpack/framework/open_telemetry_javaagent.rb
cp lib/java_buildpack/framework/new_relic_agent.rb build/staging/lib/java_buildpack/framework/new_relic_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/new_relic_agent.rb
cp lib/java_buildpack/framework/multi_buildpack.rb build/staging/lib/java_buildpack/framework/multi_buildpack.rb
chmod 644 build/staging/lib/java_buildpack/framework/multi_buildpack.rb
cp lib/java_buildpack/framework/metric_writer.rb build/staging/lib/java_buildpack/framework/metric_writer.rb
chmod 644 build/staging/lib/java_buildpack/framework/metric_writer.rb
cp lib/java_buildpack/framework/maria_db_jdbc.rb build/staging/lib/java_buildpack/framework/maria_db_jdbc.rb
chmod 644 build/staging/lib/java_buildpack/framework/maria_db_jdbc.rb
cp lib/java_buildpack/framework/luna_security_provider.rb build/staging/lib/java_buildpack/framework/luna_security_provider.rb
chmod 644 build/staging/lib/java_buildpack/framework/luna_security_provider.rb
cp lib/java_buildpack/framework/jrebel_agent.rb build/staging/lib/java_buildpack/framework/jrebel_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/jrebel_agent.rb
cp lib/java_buildpack/framework/jprofiler_profiler.rb build/staging/lib/java_buildpack/framework/jprofiler_profiler.rb
chmod 644 build/staging/lib/java_buildpack/framework/jprofiler_profiler.rb
cp lib/java_buildpack/framework/jmx.rb build/staging/lib/java_buildpack/framework/jmx.rb
chmod 644 build/staging/lib/java_buildpack/framework/jmx.rb
cp lib/java_buildpack/framework/java_security.rb build/staging/lib/java_buildpack/framework/java_security.rb
chmod 644 build/staging/lib/java_buildpack/framework/java_security.rb
cp lib/java_buildpack/framework/java_opts.rb build/staging/lib/java_buildpack/framework/java_opts.rb
chmod 644 build/staging/lib/java_buildpack/framework/java_opts.rb
cp lib/java_buildpack/framework/java_memory_assistant.rb build/staging/lib/java_buildpack/framework/java_memory_assistant.rb
chmod 644 build/staging/lib/java_buildpack/framework/java_memory_assistant.rb
mkdir -p build/staging/lib/java_buildpack/framework/java_memory_assistant
cp lib/java_buildpack/framework/java_memory_assistant/heap_dump_folder.rb build/staging/lib/java_buildpack/framework/java_memory_assistant/heap_dump_folder.rb
chmod 644 build/staging/lib/java_buildpack/framework/java_memory_assistant/heap_dump_folder.rb
cp lib/java_buildpack/framework/java_memory_assistant/clean_up.rb build/staging/lib/java_buildpack/framework/java_memory_assistant/clean_up.rb
chmod 644 build/staging/lib/java_buildpack/framework/java_memory_assistant/clean_up.rb
cp lib/java_buildpack/framework/java_memory_assistant/agent.rb build/staging/lib/java_buildpack/framework/java_memory_assistant/agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/java_memory_assistant/agent.rb
cp lib/java_buildpack/framework/java_cf_env.rb build/staging/lib/java_buildpack/framework/java_cf_env.rb
chmod 644 build/staging/lib/java_buildpack/framework/java_cf_env.rb
cp lib/java_buildpack/framework/jacoco_agent.rb build/staging/lib/java_buildpack/framework/jacoco_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/jacoco_agent.rb
cp lib/java_buildpack/framework/introscope_agent.rb build/staging/lib/java_buildpack/framework/introscope_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/introscope_agent.rb
cp lib/java_buildpack/framework/google_stackdriver_profiler.rb build/staging/lib/java_buildpack/framework/google_stackdriver_profiler.rb
chmod 644 build/staging/lib/java_buildpack/framework/google_stackdriver_profiler.rb
cp lib/java_buildpack/framework/google_stackdriver_debugger.rb build/staging/lib/java_buildpack/framework/google_stackdriver_debugger.rb
chmod 644 build/staging/lib/java_buildpack/framework/google_stackdriver_debugger.rb
cp lib/java_buildpack/framework/elastic_apm_agent.rb build/staging/lib/java_buildpack/framework/elastic_apm_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/elastic_apm_agent.rb
cp lib/java_buildpack/framework/dynatrace_one_agent.rb build/staging/lib/java_buildpack/framework/dynatrace_one_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/dynatrace_one_agent.rb
cp lib/java_buildpack/framework/debug.rb build/staging/lib/java_buildpack/framework/debug.rb
chmod 644 build/staging/lib/java_buildpack/framework/debug.rb
cp lib/java_buildpack/framework/datadog_javaagent.rb build/staging/lib/java_buildpack/framework/datadog_javaagent.rb
chmod 644 build/staging/lib/java_buildpack/framework/datadog_javaagent.rb
cp lib/java_buildpack/framework/contrast_security_agent.rb build/staging/lib/java_buildpack/framework/contrast_security_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/contrast_security_agent.rb
cp lib/java_buildpack/framework/container_security_provider.rb build/staging/lib/java_buildpack/framework/container_security_provider.rb
chmod 644 build/staging/lib/java_buildpack/framework/container_security_provider.rb
cp lib/java_buildpack/framework/container_customizer.rb build/staging/lib/java_buildpack/framework/container_customizer.rb
chmod 644 build/staging/lib/java_buildpack/framework/container_customizer.rb
Caching https://storage.googleapis.com/java-buildpack-dependencies/jacoco/index.yml
cp lib/java_buildpack/framework/client_certificate_mapper.rb build/staging/lib/java_buildpack/framework/client_certificate_mapper.rb
chmod 644 build/staging/lib/java_buildpack/framework/client_certificate_mapper.rb
cp lib/java_buildpack/framework/checkmarx_iast_agent.rb build/staging/lib/java_buildpack/framework/checkmarx_iast_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/checkmarx_iast_agent.rb
cp lib/java_buildpack/framework/azure_application_insights_agent.rb build/staging/lib/java_buildpack/framework/azure_application_insights_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/azure_application_insights_agent.rb
cp lib/java_buildpack/framework/aspectj_weaver_agent.rb build/staging/lib/java_buildpack/framework/aspectj_weaver_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/aspectj_weaver_agent.rb
cp lib/java_buildpack/framework/app_dynamics_agent.rb build/staging/lib/java_buildpack/framework/app_dynamics_agent.rb
chmod 644 build/staging/lib/java_buildpack/framework/app_dynamics_agent.rb
cp lib/java_buildpack/container.rb build/staging/lib/java_buildpack/container.rb
Caching https://storage.googleapis.com/java-buildpack-dependencies/java-cfenv/index.yml
chmod 644 build/staging/lib/java_buildpack/container.rb
mkdir -p build/staging/lib/java_buildpack/container
cp lib/java_buildpack/container/tomcat.rb build/staging/lib/java_buildpack/container/tomcat.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat.rb
mkdir -p build/staging/lib/java_buildpack/container/tomcat
cp lib/java_buildpack/container/tomcat/tomcat_utils.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_utils.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_utils.rb
cp lib/java_buildpack/container/tomcat/tomcat_setenv.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_setenv.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_setenv.rb
cp lib/java_buildpack/container/tomcat/tomcat_redis_store.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_redis_store.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_redis_store.rb
cp lib/java_buildpack/container/tomcat/tomcat_logging_support.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_logging_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_logging_support.rb
cp lib/java_buildpack/container/tomcat/tomcat_lifecycle_support.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_lifecycle_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_lifecycle_support.rb
cp lib/java_buildpack/container/tomcat/tomcat_instance.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_instance.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_instance.rb
cp lib/java_buildpack/container/tomcat/tomcat_insight_support.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_insight_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_insight_support.rb
cp lib/java_buildpack/container/tomcat/tomcat_geode_store.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_geode_store.rb
Caching https://raw.githubusercontent.com/SAP/java-memory-assistant/repository/index.yml
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_geode_store.rb
Caching https://raw.githubusercontent.com/SAP/java-memory-assistant-tools/repository-cu/index.yml
cp lib/java_buildpack/container/tomcat/tomcat_external_configuration.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_external_configuration.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_external_configuration.rb
cp lib/java_buildpack/container/tomcat/tomcat_access_logging_support.rb build/staging/lib/java_buildpack/container/tomcat/tomcat_access_logging_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tomcat/tomcat_access_logging_support.rb
cp lib/java_buildpack/container/tc_server.rb build/staging/lib/java_buildpack/container/tc_server.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server.rb
mkdir -p build/staging/lib/java_buildpack/container/tc_server
cp lib/java_buildpack/container/tc_server/tc_server_utils.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_utils.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_utils.rb
cp lib/java_buildpack/container/tc_server/tc_server_setenv.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_setenv.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_setenv.rb
cp lib/java_buildpack/container/tc_server/tc_server_redis_store.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_redis_store.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_redis_store.rb
cp lib/java_buildpack/container/tc_server/tc_server_logging_support.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_logging_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_logging_support.rb
cp lib/java_buildpack/container/tc_server/tc_server_lifecycle_support.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_lifecycle_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_lifecycle_support.rb
cp lib/java_buildpack/container/tc_server/tc_server_instance.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_instance.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_instance.rb
cp lib/java_buildpack/container/tc_server/tc_server_insight_support.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_insight_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_insight_support.rb
cp lib/java_buildpack/container/tc_server/tc_server_access_logging_support.rb build/staging/lib/java_buildpack/container/tc_server/tc_server_access_logging_support.rb
chmod 644 build/staging/lib/java_buildpack/container/tc_server/tc_server_access_logging_support.rb
cp lib/java_buildpack/container/spring_boot_efficiency.rb build/staging/lib/java_buildpack/container/spring_boot_efficiency.rb
chmod 644 build/staging/lib/java_buildpack/container/spring_boot_efficiency.rb
cp lib/java_buildpack/container/spring_boot_cli.rb build/staging/lib/java_buildpack/container/spring_boot_cli.rb
chmod 644 build/staging/lib/java_buildpack/container/spring_boot_cli.rb
cp lib/java_buildpack/container/spring_boot.rb build/staging/lib/java_buildpack/container/spring_boot.rb
chmod 644 build/staging/lib/java_buildpack/container/spring_boot.rb
cp lib/java_buildpack/container/ratpack.rb build/staging/lib/java_buildpack/container/ratpack.rb
chmod 644 build/staging/lib/java_buildpack/container/ratpack.rb
cp lib/java_buildpack/container/play_framework.rb build/staging/lib/java_buildpack/container/play_framework.rb
chmod 644 build/staging/lib/java_buildpack/container/play_framework.rb
cp lib/java_buildpack/container/java_main.rb build/staging/lib/java_buildpack/container/java_main.rb
chmod 644 build/staging/lib/java_buildpack/container/java_main.rb
cp lib/java_buildpack/container/groovy.rb build/staging/lib/java_buildpack/container/groovy.rb
chmod 644 build/staging/lib/java_buildpack/container/groovy.rb
cp lib/java_buildpack/container/dist_zip_like.rb build/staging/lib/java_buildpack/container/dist_zip_like.rb
chmod 644 build/staging/lib/java_buildpack/container/dist_zip_like.rb
cp lib/java_buildpack/container/dist_zip.rb build/staging/lib/java_buildpack/container/dist_zip.rb
chmod 644 build/staging/lib/java_buildpack/container/dist_zip.rb
cp lib/java_buildpack/component.rb build/staging/lib/java_buildpack/component.rb
chmod 644 build/staging/lib/java_buildpack/component.rb
mkdir -p build/staging/lib/java_buildpack/component
cp lib/java_buildpack/component/versioned_dependency_component.rb build/staging/lib/java_buildpack/component/versioned_dependency_component.rb
chmod 644 build/staging/lib/java_buildpack/component/versioned_dependency_component.rb
cp lib/java_buildpack/component/services.rb build/staging/lib/java_buildpack/component/services.rb
chmod 644 build/staging/lib/java_buildpack/component/services.rb
cp lib/java_buildpack/component/security_providers.rb build/staging/lib/java_buildpack/component/security_providers.rb
chmod 644 build/staging/lib/java_buildpack/component/security_providers.rb
cp lib/java_buildpack/component/root_libraries.rb build/staging/lib/java_buildpack/component/root_libraries.rb
chmod 644 build/staging/lib/java_buildpack/component/root_libraries.rb
cp lib/java_buildpack/component/networking.rb build/staging/lib/java_buildpack/component/networking.rb
chmod 644 build/staging/lib/java_buildpack/component/networking.rb
cp lib/java_buildpack/component/mutable_java_home.rb build/staging/lib/java_buildpack/component/mutable_java_home.rb
chmod 644 build/staging/lib/java_buildpack/component/mutable_java_home.rb
cp lib/java_buildpack/component/modular_component.rb build/staging/lib/java_buildpack/component/modular_component.rb
chmod 644 build/staging/lib/java_buildpack/component/modular_component.rb
cp lib/java_buildpack/component/java_opts.rb build/staging/lib/java_buildpack/component/java_opts.rb
chmod 644 build/staging/lib/java_buildpack/component/java_opts.rb
cp lib/java_buildpack/component/immutable_java_home.rb build/staging/lib/java_buildpack/component/immutable_java_home.rb
chmod 644 build/staging/lib/java_buildpack/component/immutable_java_home.rb
cp lib/java_buildpack/component/extension_directories.rb build/staging/lib/java_buildpack/component/extension_directories.rb
chmod 644 build/staging/lib/java_buildpack/component/extension_directories.rb
cp lib/java_buildpack/component/environment_variables.rb build/staging/lib/java_buildpack/component/environment_variables.rb
chmod 644 build/staging/lib/java_buildpack/component/environment_variables.rb
cp lib/java_buildpack/component/droplet.rb build/staging/lib/java_buildpack/component/droplet.rb
chmod 644 build/staging/lib/java_buildpack/component/droplet.rb
cp lib/java_buildpack/component/base_component.rb build/staging/lib/java_buildpack/component/base_component.rb
chmod 644 build/staging/lib/java_buildpack/component/base_component.rb
cp lib/java_buildpack/component/application.rb build/staging/lib/java_buildpack/component/application.rb
chmod 644 build/staging/lib/java_buildpack/component/application.rb
Caching https://download.run.pivotal.io/jprofiler/index.yml
cp lib/java_buildpack/component/additional_libraries.rb build/staging/lib/java_buildpack/component/additional_libraries.rb
chmod 644 build/staging/lib/java_buildpack/component/additional_libraries.rb
cp lib/java_buildpack/buildpack_version.rb build/staging/lib/java_buildpack/buildpack_version.rb
chmod 644 build/staging/lib/java_buildpack/buildpack_version.rb
cp lib/java_buildpack/buildpack.rb build/staging/lib/java_buildpack/buildpack.rb
chmod 644 build/staging/lib/java_buildpack/buildpack.rb
mkdir -p build/staging/config
cp config/zulu_jre.yml build/staging/config/zulu_jre.yml
chmod 644 build/staging/config/zulu_jre.yml
cp config/zing_jre.yml build/staging/config/zing_jre.yml
chmod 644 build/staging/config/zing_jre.yml
cp config/your_kit_profiler.yml build/staging/config/your_kit_profiler.yml
chmod 644 build/staging/config/your_kit_profiler.yml
cp config/version.yml build/staging/config/version.yml
chmod 644 build/staging/config/version.yml
cp config/verify_compliance.yml build/staging/config/verify_compliance.yml
chmod 644 build/staging/config/verify_compliance.yml
cp config/tomcat.yml build/staging/config/tomcat.yml
chmod 644 build/staging/config/tomcat.yml
cp config/tc_server.yml build/staging/config/tc_server.yml
chmod 644 build/staging/config/tc_server.yml
cp config/takipi_agent.yml build/staging/config/takipi_agent.yml
chmod 644 build/staging/config/takipi_agent.yml
cp config/spring_boot_efficiency.yml build/staging/config/spring_boot_efficiency.yml
chmod 644 build/staging/config/spring_boot_efficiency.yml
cp config/spring_boot_cli.yml build/staging/config/spring_boot_cli.yml
chmod 644 build/staging/config/spring_boot_cli.yml
cp config/spring_auto_reconfiguration.yml build/staging/config/spring_auto_reconfiguration.yml
chmod 644 build/staging/config/spring_auto_reconfiguration.yml
cp config/splunk_otel_java_agent.yml build/staging/config/splunk_otel_java_agent.yml
chmod 644 build/staging/config/splunk_otel_java_agent.yml
cp config/sky_walking_agent.yml build/staging/config/sky_walking_agent.yml
chmod 644 build/staging/config/sky_walking_agent.yml
cp config/sealights_agent.yml build/staging/config/sealights_agent.yml
chmod 644 build/staging/config/sealights_agent.yml
cp config/sap_machine_jre.yml build/staging/config/sap_machine_jre.yml
chmod 644 build/staging/config/sap_machine_jre.yml
Caching https://dl.zeroturnaround.com/jrebel/index.yml
cp config/ruby.yml build/staging/config/ruby.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/luna-security-provider/index.yml
chmod 644 build/staging/config/ruby.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/mariadb-jdbc/index.yml
cp config/riverbed_appinternals_agent.yml build/staging/config/riverbed_appinternals_agent.yml
chmod 644 build/staging/config/riverbed_appinternals_agent.yml
cp config/repository.yml build/staging/config/repository.yml
chmod 644 build/staging/config/repository.yml
cp config/protect_app_security_provider.yml build/staging/config/protect_app_security_provider.yml
chmod 644 build/staging/config/protect_app_security_provider.yml
cp config/postgresql_jdbc.yml build/staging/config/postgresql_jdbc.yml
chmod 644 build/staging/config/postgresql_jdbc.yml
cp config/packaging.yml build/staging/config/packaging.yml
chmod 644 build/staging/config/packaging.yml
cp config/oracle_jre.yml build/staging/config/oracle_jre.yml
chmod 644 build/staging/config/oracle_jre.yml
cp config/open_telemetry_javaagent.yml build/staging/config/open_telemetry_javaagent.yml
chmod 644 build/staging/config/open_telemetry_javaagent.yml
cp config/open_jdk_jre.yml build/staging/config/open_jdk_jre.yml
chmod 644 build/staging/config/open_jdk_jre.yml
cp config/new_relic_agent.yml build/staging/config/new_relic_agent.yml
chmod 644 build/staging/config/new_relic_agent.yml
cp config/metric_writer.yml build/staging/config/metric_writer.yml
chmod 644 build/staging/config/metric_writer.yml
cp config/maria_db_jdbc.yml build/staging/config/maria_db_jdbc.yml
chmod 644 build/staging/config/maria_db_jdbc.yml
cp config/luna_security_provider.yml build/staging/config/luna_security_provider.yml
chmod 644 build/staging/config/luna_security_provider.yml
cp config/logging.yml build/staging/config/logging.yml
chmod 644 build/staging/config/logging.yml
cp config/jrebel_agent.yml build/staging/config/jrebel_agent.yml
chmod 644 build/staging/config/jrebel_agent.yml
cp config/jprofiler_profiler.yml build/staging/config/jprofiler_profiler.yml
chmod 644 build/staging/config/jprofiler_profiler.yml
cp config/jmx.yml build/staging/config/jmx.yml
chmod 644 build/staging/config/jmx.yml
cp config/java_opts.yml build/staging/config/java_opts.yml
chmod 644 build/staging/config/java_opts.yml
cp config/java_memory_assistant.yml build/staging/config/java_memory_assistant.yml
chmod 644 build/staging/config/java_memory_assistant.yml
cp config/java_main.yml build/staging/config/java_main.yml
chmod 644 build/staging/config/java_main.yml
cp config/java_cf_env.yml build/staging/config/java_cf_env.yml
chmod 644 build/staging/config/java_cf_env.yml
cp config/jacoco_agent.yml build/staging/config/jacoco_agent.yml
chmod 644 build/staging/config/jacoco_agent.yml
cp config/introscope_agent.yml build/staging/config/introscope_agent.yml
chmod 644 build/staging/config/introscope_agent.yml
cp config/ibm_jre.yml build/staging/config/ibm_jre.yml
chmod 644 build/staging/config/ibm_jre.yml
cp config/groovy.yml build/staging/config/groovy.yml
chmod 644 build/staging/config/groovy.yml
cp config/graal_vm_jre.yml build/staging/config/graal_vm_jre.yml
chmod 644 build/staging/config/graal_vm_jre.yml
cp config/google_stackdriver_profiler.yml build/staging/config/google_stackdriver_profiler.yml
chmod 644 build/staging/config/google_stackdriver_profiler.yml
cp config/google_stackdriver_debugger.yml build/staging/config/google_stackdriver_debugger.yml
chmod 644 build/staging/config/google_stackdriver_debugger.yml
cp config/elastic_apm_agent.yml build/staging/config/elastic_apm_agent.yml
chmod 644 build/staging/config/elastic_apm_agent.yml
cp config/dist_zip_like.yml build/staging/config/dist_zip_like.yml
chmod 644 build/staging/config/dist_zip_like.yml
cp config/dist_zip.yml build/staging/config/dist_zip.yml
chmod 644 build/staging/config/dist_zip.yml
cp config/debug.yml build/staging/config/debug.yml
chmod 644 build/staging/config/debug.yml
cp config/datadog_javaagent.yml build/staging/config/datadog_javaagent.yml
chmod 644 build/staging/config/datadog_javaagent.yml
cp config/contrast_security_agent.yml build/staging/config/contrast_security_agent.yml
chmod 644 build/staging/config/contrast_security_agent.yml
cp config/container_security_provider.yml build/staging/config/container_security_provider.yml
chmod 644 build/staging/config/container_security_provider.yml
cp config/container_customizer.yml build/staging/config/container_customizer.yml
chmod 644 build/staging/config/container_customizer.yml
cp config/components.yml build/staging/config/components.yml
chmod 644 build/staging/config/components.yml
cp config/client_certificate_mapper.yml build/staging/config/client_certificate_mapper.yml
chmod 644 build/staging/config/client_certificate_mapper.yml
cp config/cache.yml build/staging/config/cache.yml
chmod 644 build/staging/config/cache.yml
cp config/azure_application_insights_agent.yml build/staging/config/azure_application_insights_agent.yml
chmod 644 build/staging/config/azure_application_insights_agent.yml
cp config/aspectj_weaver_agent.yml build/staging/config/aspectj_weaver_agent.yml
chmod 644 build/staging/config/aspectj_weaver_agent.yml
cp config/app_dynamics_agent.yml build/staging/config/app_dynamics_agent.yml
chmod 644 build/staging/config/app_dynamics_agent.yml
mkdir -p build/staging/rakelib
cp rakelib/versions_task.rb build/staging/rakelib/versions_task.rb
chmod 644 build/staging/rakelib/versions_task.rb
cp rakelib/utils.rb build/staging/rakelib/utils.rb
chmod 644 build/staging/rakelib/utils.rb
cp rakelib/stage_buildpack_task.rb build/staging/rakelib/stage_buildpack_task.rb
chmod 644 build/staging/rakelib/stage_buildpack_task.rb
cp rakelib/package_task.rb build/staging/rakelib/package_task.rb
chmod 644 build/staging/rakelib/package_task.rb
cp rakelib/package.rb build/staging/rakelib/package.rb
chmod 644 build/staging/rakelib/package.rb
cp rakelib/dependency_cache_task.rb build/staging/rakelib/dependency_cache_task.rb
chmod 644 build/staging/rakelib/dependency_cache_task.rb
cp Rakefile build/staging/Rakefile
chmod 644 build/staging/Rakefile
cp Gemfile.lock build/staging/Gemfile.lock
chmod 644 build/staging/Gemfile.lock
cp Gemfile build/staging/Gemfile
chmod 644 build/staging/Gemfile
mkdir -p build/staging/bin
cp bin/run build/staging/bin/run
chmod 755 build/staging/bin/run
cp bin/ruby-run build/staging/bin/ruby-run
chmod 755 build/staging/bin/ruby-run
cp bin/release build/staging/bin/release
chmod 755 build/staging/bin/release
cp bin/finalize build/staging/bin/finalize
chmod 755 build/staging/bin/finalize
cp bin/detect build/staging/bin/detect
chmod 755 build/staging/bin/detect
cp bin/compile build/staging/bin/compile
chmod 755 build/staging/bin/compile
Caching https://buildpacks.cloudfoundry.org/dependencies/ruby/ruby_3.2.8_linux_x64_cflinuxfs4_18ec473d.tgz
Caching https://storage.googleapis.com/java-buildpack-dependencies/metric-writer/index.yml
Caching https://download.run.pivotal.io/new-relic/index.yml
Caching https://raw.githubusercontent.com/open-telemetry/opentelemetry-java-instrumentation/cloudfoundry/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/postgresql-jdbc/index.yml
Caching https://pcf-instrumentation-download.steelcentral.net/index.yml
Caching https://agents.sealights.co/pcf/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/auto-reconfiguration/index.yml
Caching https://raw.githubusercontent.com/signalfx/splunk-otel-java/main/deployments/cloudfoundry/index.yml
Caching https://storage.googleapis.com/java-buildpack-dependencies/sky-walking/index.yml
Caching https://download.run.pivotal.io/your-kit/bionic/x86_64/index.yml
Caching https://download.run.pivotal.io/your-kit/jammy/x86_64/index.yml
Caching https://get.takipi.com/cloudfoundry/index.yml
Caching https://raw.githubusercontent.com/cloudfoundry/ruby-buildpack/master/java-index/index.yml
Caching https://usw1.packages.broadcom.com/artifactory/tanzu-build-generic-prod-local/java-buildpack-dependencies/spring-kit-cli/spring-kit-cli-0.5.0.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/groovy/groovy-2.5.23.zip
Caching https://storage.googleapis.com/java-buildpack-dependencies/spring-boot-cli/spring-boot-cli-2.7.18.tar.gz
Caching https://usw1.packages.broadcom.com/artifactory/tanzu-build-generic-prod-local/java-buildpack-dependencies/tc-server/tc-server-4.1.49.tar.gz
Caching https://usw1.packages.broadcom.com/artifactory/tanzu-build-generic-prod-local/java-buildpack-dependencies/tc-server/tc-server-10.1.45_B.tar.gz
Caching https://usw1.packages.broadcom.com/artifactory/tanzu-build-generic-prod-local/java-buildpack-dependencies/tc-server/tc-server-11.0.11_A.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-lifecycle-support/tomcat-lifecycle-support-3.4.0-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-logging-support/tomcat-logging-support-3.4.0-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-access-logging-support/tomcat-access-logging-support-3.4.0-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-logging-support/tomcat-logging-support-3.4.0-RELEASE.jar
Caching https://java-buildpack.cloudfoundry.org/redis-store/redis-store-1.3.6-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-access-logging-support/tomcat-access-logging-support-3.4.0-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat/tomcat-10.1.54.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat/tomcat-9.0.117.tar.gz
Caching https://java-buildpack-tomcat-gemfire-store.s3.us-west-2.amazonaws.com/java-buildpack-tomcat-gemfire-store-2.1.2.tar
Caching https://storage.googleapis.com/java-buildpack-dependencies/tomcat-lifecycle-support/tomcat-lifecycle-support-3.4.0-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/bellsoft-jre11.0.29%2B12-linux-amd64.tar.gz
Caching https://java-buildpack.cloudfoundry.org/redis-store/redis-store-1.3.6-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/bellsoft-jre11.0.29%2B12-linux-amd64.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/bellsoft-jre17.0.18%2B10-linux-amd64.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/bellsoft-jre17.0.18%2B10-linux-amd64.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/bellsoft-jre21.0.10%2B10-linux-amd64.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/bellsoft-jre21.0.10%2B10-linux-amd64.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/bellsoft-jre25.0.2%2B12-linux-amd64.tar.gz
Caching https://s3.amazonaws.com/app-takipi-com/deploy/linux/takipi-agent-4.84.0.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/bellsoft-jre25.0.2%2B12-linux-amd64.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/bionic/x86_64/bellsoft-jre8u482%2B10-linux-amd64.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/openjdk/jammy/x86_64/bellsoft-jre8u482%2B10-linux-amd64.tar.gz
Caching https://java-buildpack.cloudfoundry.org/jvmkill/bionic/x86_64/jvmkill-1.17.0-RELEASE.so
Caching https://java-buildpack.cloudfoundry.org/jvmkill/jammy/x86_64/jvmkill-1.17.0-RELEASE.so
Caching https://java-buildpack.cloudfoundry.org/memory-calculator/bionic/x86_64/memory-calculator-3.13.0-RELEASE.tar.gz
Caching https://java-buildpack.cloudfoundry.org/memory-calculator/jammy/x86_64/memory-calculator-3.13.0-RELEASE.tar.gz
Caching https://local-appd-repo.apps.lab.pcfdemo.net/appdynamics/appdynamics-24.11.0-36469.tar.gz
Caching https://storage.googleapis.com/java-buildpack-dependencies/azure-application-insights/azure-application-insights-3.7.8.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/client-certificate-mapper/client-certificate-mapper-2.0.1.jar
Caching https://java-buildpack.cloudfoundry.org/container-customizer/container-customizer-2.6.0-RELEASE.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/container-security-provider/container-security-provider-1.20.0-RELEASE.jar
Caching https://download.run.pivotal.io/contrast-security/contrast-agent-6.27.0.jar
Caching https://repo1.maven.org/maven2/com/datadoghq/dd-java-agent/1.61.0/dd-java-agent-1.61.0.jar
Caching https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.55.5/elastic-apm-agent-1.55.5.jar
Caching https://java-buildpack.cloudfoundry.org/google-stackdriver-profiler/bionic/x86_64/google-stackdriver-profiler-0.1.0.tar.gz
Caching https://java-buildpack.cloudfoundry.org/google-stackdriver-profiler/bionic/x86_64/google-stackdriver-profiler-0.1.0.tar.gz
Caching https://packages.broadcom.com/artifactory/apm-agents/agent-default-25.10.1_10.tar
Caching https://storage.googleapis.com/java-buildpack-dependencies/jacoco/jacoco-0.8.14.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/java-cfenv/java-cfenv-3.5.1.jar
Caching https://github.com/SAP/java-memory-assistant/releases/download/0.5.0/java-memory-assistant-0.5.0.jar
Caching https://github.com/SAP/java-memory-assistant-tools/releases/download/0.1.0/cleanup-linux-amd64-0.1.0.zip
Caching https://download.run.pivotal.io/jprofiler/jprofiler-15.0.4.tar.gz
Caching https://dl.zeroturnaround.com/jrebel/releases/jrebel-2026.2.0-nosetup.zip
Caching https://java-buildpack.cloudfoundry.org/luna-security-provider/LunaClient-Minimal-v7.4.0-226.x86_64.tar
Caching https://java-buildpack.cloudfoundry.org/mariadb-jdbc/mariadb-jdbc-2.7.9.jar
Caching https://java-buildpack.cloudfoundry.org/metric-writer/metric-writer-3.5.0-RELEASE.jar
Caching https://download.run.pivotal.io/new-relic/new-relic-9.2.0.jar
Caching https://repo1.maven.org/maven2/io/opentelemetry/javaagent/opentelemetry-javaagent/2.26.1/opentelemetry-javaagent-2.26.1.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/postgresql-jdbc/postgresql-jdbc-42.7.10.jar
Caching https://pcf-instrumentation-download.steelcentral.net/riverbed-appinternals-agent-11.8.5_BL527.zip
Caching https://agents.sealights.co/sealights-java/sealights-java-4.0.2570.zip
Caching https://java-buildpack.cloudfoundry.org/auto-reconfiguration/auto-reconfiguration-2.12.0-RELEASE.jar
Caching https://github.com/signalfx/splunk-otel-java/releases/download/v2.26.1/splunk-otel-javaagent.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/sky-walking/sky-walking-9.6.0.tar.gz
Caching https://pcf-instrumentation-download.steelcentral.net/riverbed-appinternals-agent-11.8.5_BL527.zip
Caching https://agents.sealights.co/sealights-java/sealights-java-4.0.2570.zip
Caching https://java-buildpack.cloudfoundry.org/auto-reconfiguration/auto-reconfiguration-2.12.0-RELEASE.jar
Caching https://github.com/signalfx/splunk-otel-java/releases/download/v2.26.1/splunk-otel-javaagent.jar
Caching https://storage.googleapis.com/java-buildpack-dependencies/sky-walking/sky-walking-9.6.0.tar.gz
Caching https://download.run.pivotal.io/your-kit/bionic/x86_64/your-kit-2025.9.191.so
Caching https://download.run.pivotal.io/your-kit/jammy/x86_64/your-kit-2025.9.191.so
Creating build/java-buildpack-offline-v4.85.0.zip
```