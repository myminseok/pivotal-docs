# test sso
https://github.com/pivotal-cf/identity-sample-apps

# test rabbitmq 
- guide: https://docs.pivotal.io/rabbitmq-cf/1-20/index.html
- app: https://github.com/rabbitmq/workloads/tree/master/resiliency#resilient-applications-in-java-handle-connection-failures-and-more
- https://github.com/pivotal-cf/rabbit-example-app

- BACKUP & recovery; https://docs.pivotal.io/rabbitmq-cf/1-19/troubleshoot.html#backup
- network partition: https://www.rabbitmq.com/partitions.html


```
git clone https://github.com/pivotal-cf/rabbit-example-app

curl https://rabbit-example-app.apps.CF_DOMAIN/store -XPOST -d 'test' -k
curl https://rabbit-example-app.apps.CF_DOMAIN/store  -k
```

# test redis
- app: https://github.com/pivotal-cf/cf-redis-example-app
```
export APP=redis-example-app.apps.CF_DOMAIN
curl -X PUT $APP/foo -d 'data=bar' -k
curl -X GET $APP/foo -k
curl -X DELETE $APP/foo -k

```

# test gemfire
- https://docs.pivotal.io/p-cloud-cache/1-12/
- enable single instance upgrade: https://docs.pivotal.io/p-cloud-cache/1-12/upgrade.html#enable-individual-upgrades
- limitation: https://docs.pivotal.io/p-cloud-cache/1-12/usage.html
- sample app (session caching): 
*      https://docs.pivotal.io/p-cloud-cache/1-12/Spring-SessionState.html
*      https://github.com/pivotal-cf/http-session-caching
*      https://tanzu.vmware.com/application-modernization-recipes/replatforming/offload-http-sessions-with-spring-session-and-redis
- backup: https://docs.pivotal.io/p-cloud-cache/1-12/backupandrestore.html
- compaction: https://gemfire.docs.pivotal.io/910/geode/managing/disk_storage/compacting_disk_stores.html#compacting_disk_stores
- instance sharing: bind-service, unbind-service, read/view only
*  https://docs.pivotal.io/p-cloud-cache/1-12/dev-instance-sharing.html
*  https://docs.cloudfoundry.org/devguide/services/sharing-instances.html



# test  mongodb cli 
```
mongo --host IP:27017 -u root -p PASS

MongoDB shell version v4.0.13
connecting to: mongodb://10.13.127.63:27017/?gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("0bd22863-e301-4ca0-87cb-ba7490514992") }
MongoDB server version: 4.0.13

rs0:PRIMARY> show dbs
admin   0.000GB
config  0.000GB
local   0.000GB

rs0:PRIMARY> use test
switched to db test

rs0:PRIMARY> db.test.insert({"key1":"value1"});
WriteResult({ "nInserted" : 1 })

rs0:PRIMARY> db.test.count()

rs0:PRIMARY> db.test.find({"key1":"value1"});
{ "_id" : ObjectId("5eb268d6c5ad1fe520ad1694"), "key1" : "value1" }
rs0:PRIMARY>

rs0:PRIMARY> show collections;

rs0:PRIMARY> db.test.drop();

rs0:PRIMARY> show collections;

```

# test  mongodump
https://docs.mongodb.com/manual/tutorial/backup-and-restore-tools/
```
mongodump --host IP --port 27017 -u root -p PASS  --out=./backup
find ./backup/
./backup/
./backup/test
./backup/test/test.bson
./backup/test/test.metadata.json
./backup/admin
./backup/admin/system.version.bson
./backup/admin/system.version.metadata.json
./backup/admin/system.users.bson
./backup/admin/system.users.metadata.json
```

# test mongorestore
```
mongorestore  --host IP --port 27017 --authenticationDatabase=admin  -u root -p PASS  ./backup
2020-05-06T07:47:49.764+0000	preparing collections to restore from
2020-05-06T07:47:49.817+0000	reading metadata for test.test from backup/test/test.metadata.json
2020-05-06T07:47:49.871+0000	restoring test.test from backup/test/test.bson
2020-05-06T07:47:49.909+0000	no indexes to restore
2020-05-06T07:47:49.910+0000	finished restoring test.test (1 document)
2020-05-06T07:47:49.910+0000	restoring users from backup/admin/system.users.bson
2020-05-06T07:47:50.072+0000	done
```



