## check container readiness. some container is running state even if the container is not ready.
##     state     since                  cpu    memory         disk           logging        details
## #0   running   2025-02-19T06:12:30Z   0.3%   232.3M of 1G   224.8M of 1G   0/s of 16K/s
## #1   running   2025-02-19T06:12:30Z   0.3%   219.3M of 1G   224.8M of 1G   0/s of 16K/s
## #2   running   2025-02-19T06:17:06Z   0.0%   0 of 0         0 of 0         0/s of 0/s     insufficient resources: memory
##


#!/bin/bash

app_name='spring-music'
desired_count=3

ready_count=$(cf curl /v2/apps/$(cf app $app_name --guid)/stats | jq  -r '.[].stats.usage | select(.cpu != 0 and .mem != 0 )| .mem' | wc -l)
if [ $ready_count -eq $desired_count ]; then
  echo "success $ready_count/$desired_count"
else
  echo "mismatch $ready_count/$desired_count"
fi
