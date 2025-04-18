refer to https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-platform-for-cloud-foundry/10-0/tpcf/configuring.html#limitations-considerations


### login to Ops Manager uaa
[opsman_login_uaac](opsman_login_uaac.md)


### export uaac access token

```
$ uaac contexts

## copy access token and export to 

$ export TOKEN=

```

### customize max_in_flight for the product 

```    
curl "https://EXAMPLE.com/api/v0/staged/products/PRODUCT-TYPE1-GUID/max_in_flight" \
    -X PUT \
    -H "Authorization: Bearer UAA_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
          "max_in_flight": {
            "JOB_1_GUID": 1,
            "JOB_2_GUID": "20%",
            "JOB_3_GUID": "default"
          }
        }'
```



### using om cli
#### env.yml
https://docs.vmware.com/en/Platform-Automation-Toolkit-for-VMware-Tanzu/5.1/vmware-automation-toolkit/GUID-docs-how-to-guides-configuring-env.html

#### update 
```
 om -e env.yml curl -p /api/v0/staged/products

 om -e env.yml curl -p /api/v0/staged/products/cf-05c0b7494ba8ddb50eb8/max_in_flight > cf_max_in_flight.txt

 cat cf_max_in_flight.txt
 {
  "max_in_flight": {
    "database-e48a576629161b999f2d": 1,
    "blobstore-aa8ab2573e3d5e2853a3": 1,
    "control-a23d48182f5d25844564": 1,
    "compute-2700aca2a334b412ad3f": "4%",
    "nats-192f264638d24a52fea0": 1,
    "nfs_server-e0740229334b7204e651": 1,
    "mysql_proxy-bfdc0ca26c0393998d47": 1,
    "mysql-25695f071abe7d6e8f51": 1,
    "backup_restore-fc14e8f0298724e59a51": 1,
    "diego_database-0458cb4bc58f9daa79a8": 1,
    "uaa-ce7e4d49accd9856116a": 1,
    "cloud_controller-1af418993d109b89c56e": 1,
    "cloud_controller_worker-5daca3d82bf3af877164": 1,
    "ha_proxy-85d81e7c2f9b804974b8": 1,
    "diego_brain-b3eb28532fc3521e3724": 1,
    "router-4afa33b7b82650b1381c": 1,
    "tcp_router-2b71b9a8d7210f0f2ea6": 1,
    "mysql_monitor-29e9689c2350f685337f": 1,
    "diego_cell-c5ce5e0ee4a509914784": "4%",
    "loggregator_trafficcontroller-1c383299d19117cbb93b": 1,
    "log_cache-7efa470164f52f54c90f": "20%",
    "clock_global-e942fa137f0bc58276be": 1,
    "doppler-3264d29e2bc31283819c": 1,
    "credhub-e2ae53908f1e4f9021fc": 1
  }
}


 om -e env.yml curl -p /api/v0/staged/products/cf-05c0b7494ba8ddb50eb8/max_in_flight -x PUT -d @cf_max_in_flight.txt
 Status: 200 OK
 
```
    
