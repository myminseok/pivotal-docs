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
