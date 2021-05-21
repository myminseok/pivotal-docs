- https://docs.pivotal.io/p-cloud-cache/1-12/
- enable single instance upgrade: https://docs.pivotal.io/p-cloud-cache/1-12/upgrade.html#enable-individual-upgrades
- limitation: https://docs.pivotal.io/p-cloud-cache/1-12/usage.html
- backup: https://docs.pivotal.io/p-cloud-cache/1-12/backupandrestore.html
- compaction: https://gemfire.docs.pivotal.io/910/geode/managing/disk_storage/compacting_disk_stores.html#compacting_disk_stores

## instance sharing: 
- bind-service, unbind-service, read/view only
- https://docs.pivotal.io/p-cloud-cache/1-12/dev-instance-sharing.html
- https://docs.cloudfoundry.org/devguide/services/sharing-instances.html
  
## session state caching
### using tomcat app
- guide: https://docs.pivotal.io/p-cloud-cache/1-13/Spring-SessionState.html#tomcat
- guide: https://docs.pivotal.io/p-cloud-cache/1-13/session-caching.html
- sample: https://github.com/pivotal-cf/http-session-caching
### using spring session:
- guide: https://docs.pivotal.io/p-cloud-cache/1-13/spring-session.html
- sample(org.springframework.geode:spring-geode-starter-session): https://github.com/gemfire/spring-for-apache-geode-examples/tree/main/session-state

### other
- https://tanzu.vmware.com/application-modernization-recipes/replatforming/offload-http-sessions-with-spring-session-and-redis
