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
