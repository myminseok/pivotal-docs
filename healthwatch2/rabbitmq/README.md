## Fix for RabbitMQ dashboard on healthwatch 2.3.0

this is temporary solution to mitigate following errors on grafana-rabbitmq dashboard
```
Status: 500. Message: execution: found duplicate series for the match group {instance="192.168.0.81:9090", job="healthwatch-pas-exporter"} on the right hand-side of the operation: [{__name__="rabbitmq_identity_info", deployment="service-instance_c6253408-a521-4a41-ac7f-9c96abc22b59", exported_job="rabbitmq-server", index="2303800a-422c-41f3-a3ef-50654f2af4ee", instance="192.168.0.81:9090", ip="192.168.0.93", job="healthwatch-pas-exporter", origin="p.rabbitmq", rabbitmq_cluster="service-instance_c6253408-a521-4a41-ac7f-9c96abc22b59", rabbitmq_cluster_permanent_id="rabbitmq-cluster-id-C6xv3B2JRrvfjjcaEf6WLQ", rabbitmq_node="rabbit@2303800a-422c-41f3-a3ef-50654f2af4ee.rabbitmq-server.network.service-instance-c6253408-a521-4a41-ac7f-9c96abc22b59.bosh", scrape_instance_group="pas-exporter-gauge", source_id="c6253408-a521-4a41-ac7f-9c96abc22b59"}, {__name__="rabbitmq_identity_info", deployment="service-instance_c6253408-a521-4a41-ac7f-9c96abc22b59", exported_job="rabbitmq-server", index="07707b6c-507f-4f77-9c41-c66797a0484b", instance="192.168.0.81:9090", ip="192.168.0.92", job="healthwatch-pas-exporter", origin="p.rabbitmq", rabbitmq_cluster="service-instance_c6253408-a521-4a41-ac7f-9c96abc22b59", rabbitmq_cluster_permanent_id="rabbitmq-cluster-id-C6xv3B2JRrvfjjcaEf6WLQ", rabbitmq_node="rabbit@07707b6c-507f-4f77-9c41-c66797a0484b.rabbitmq-server.network.service-instance-c6253408-a521-4a41-ac7f-9c96abc22b59.bosh", scrape_instance_group="pas-exporter-gauge", source_id="c6253408-a521-4a41-ac7f-9c96abc22b59"}];many-to-many matching not allowed: matching labels must be unique on one side
```

## Import *.json to grafana.
- Erlang-Distribution-1740387099900.json
- Erlang-Distributions-Compare-1740387255108.json
- RabbitMQ-Overview-1740387330624.json
- RabbitMQ-Quorum-Queues-Raft-1740387416759.json


## Fix details 
replace promql for each chart on each dashboard as following

#### Fix 1
from
```
... on(instance, job) ...
```
to 
```
...  on(instance, job, index) ... 
```

for
- Erlang-Distribution
- Erlang-Distribution-Compare2
- RabbitMQ Overview2
- RabbitMQ-Quorum-Queues-Raft


### Fix 2
for RabbitMQ-Quorum-Queues-Raft, replace promql for each chart on each dashboard as following

```
"expr": "sum(\n  (rabbitmq_raft_log_last_written_index * on(instance, job) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster=\"$rabbitmq_cluster\", namespace=\"$namespace\"}) - \n  (rabbitmq_raft_log_snapshot_index * on(instance) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster=\"$rabbitmq_cluster\", namespace=\"$namespace\"})\n) by(queue, rabbitmq_node)",
```    
to
```
"expr": "sum(\n  (rabbitmq_raft_log_last_written_index * on(instance, job, index) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster=\"$rabbitmq_cluster\", namespace=\"$namespace\"}) - \n  (rabbitmq_raft_log_snapshot_index * on(instance, index) group_left(rabbitmq_cluster, rabbitmq_node) rabbitmq_identity_info{rabbitmq_cluster=\"$rabbitmq_cluster\", namespace=\"$namespace\"})\n) by(queue, rabbitmq_node)",
```   
