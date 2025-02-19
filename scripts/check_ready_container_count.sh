#!/bin/bash


app_name='spring-music'
desired_count=3

ready_count=$(cf curl /v2/apps/$(cf app $app_name --guid)/stats | jq  -r '.[].stats.usage | select(.cpu != 0 and .mem != 0 )| .mem' | wc -l)
if [ $ready_count -eq $desired_count ]; then
  echo "success $ready_count/$desired_count"
else
  echo "mismatch $ready_count/$desired_count"
fi
