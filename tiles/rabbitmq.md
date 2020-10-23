- guide: https://docs.pivotal.io/rabbitmq-cf/1-20/index.html
- BACKUP & recovery; https://docs.pivotal.io/rabbitmq-cf/1-19/troubleshoot.html#backup
- network partition: https://www.rabbitmq.com/partitions.html
# sample app:
https://github.com/pivotal-cf/rabbit-example-app
```
git clone https://github.com/pivotal-cf/rabbit-example-app

curl https://rabbit-example-app.apps.CF_DOMAIN/store -XPOST -d 'test' -k
curl https://rabbit-example-app.apps.CF_DOMAIN/store  -k
```
https://github.com/rabbitmq/workloads/tree/master/resiliency#resilient-applications-in-java-handle-connection-failures-and-more
