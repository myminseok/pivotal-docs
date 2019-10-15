this article shows how to add additional NIC to cell VM.

### ssh into opsmanager VM

```
ssh -i jumpbox.pem ubuntu@OPSMAN2.6-IP

ubuntu@opsman-2.6:  sudo su

root@opsman-2.6: 

```

### create a ops file
/home/ubuntu/add-nic-to-cell.yml
- 'PAS-NETWORK' for PAS-tile
-  DB-NETWORK is additional network.
```
- type: replace
  path: /instance_groups/name=diego_cell/networks/name=PAS-NETWORK/default?
  value:
    - dns
    - gateway

- type: replace
  path: /instance_groups/name=diego_cell/networks/-
  value:
    name: DB-NETWORK
```


```
chmod 777 /home/ubuntu/add-nic-to-cell.yml
```

### edit opsmanager. 
- for Isolation segment, you need to add to the if conditions.

```
vi /home/tempest-web/tempest/web/app/models/deployer/executors/bosh_executor.rb

    142       def deploy(deployment_name, manifest_path, recreate: false, recreate_persistent_disk: false)
    143         #bosh("--deployment=#{deployment_name} deploy #{manifest_path}#{' --recreate' if recreate}#{' --recreate-persistent-disks' if recreate_persistent_disk}")
    144         bosh("--deployment=#{deployment_name} deploy #{manifest_path}#{' --recreate' if recreate}#{' --recreate-persistent-disks' if recreate_persistent_disk}#{' -o /home/ubuntu/add-nic-to-cell.yml' if "#{deployment_name}".start_with?('cf-')}")
    145       end

```

### restart opsmanager.
```
service tempest-web restart
```

