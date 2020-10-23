- sample app: https://github.com/pivotal-cf/cf-redis-example-app

```
export APP=redis-example-app.apps.CF_DOMAIN
curl -X PUT $APP/foo -d 'data=bar' -k
curl -X GET $APP/foo -k
curl -X DELETE $APP/foo -k

```
