This way is not recommended. Use Opsmanager API (https://github.com/myminseok/pivotal-docs/blob/master/add-nic-to-cell-vm-via-opsman-api.md)


this article shows how to add additional NIC to cell VM.

### ssh into opsmanager VM

```
ssh -i jumpbox.pem ubuntu@OPSMAN2.6-IP

ubuntu@opsman-2.6:  sudo su

root@opsman-2.6: 

```

### create a ops file
/home/ubuntu/add-nic-to-cell.yml
- 'PAS-NETWORK': network for PAS-tile. change this value to your network name shown in opsmanager bosh director tile.
-  DB-NETWORK: additional network. change this value you defined in in opsmanager bosh director tile.
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
* following changes is only for PAS tile. for Isolation segment, you need to add to the if conditions.
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

###
now, next 'apply change'  will add a new nic to your CELL vms.
```
===== 2019-10-15 04:38:44 UTC Running "/usr/local/bin/bosh --no-color --non-interactive --tty --environment=10.10.10.21 --deployment=cf-7b6a32f059ba9157bb8f deploy /var/tempest/workspaces/default/deployments/cf-7b6a32f059ba9157bb8f.yml -o /home/ubuntu/add-nic-to-cell.yml"
Using environment '10.10.10.21' as client 'ops_manager'

Using deployment 'cf-7b6a32f059ba9157bb8f'

 instance_groups:
 - name: diego_cell
   networks:
   - name: PAS-network
     default:
      - dns
      - gateway
  - name: DB-network

Task 498045
```

Cell vm has additional NIC.
```
Deployment 'cf-7b6a32f059ba9157bb8f'

Instance                                                            Process State  AZ   IPs           VM CID                                   VM Type      Active
backup_restore/d26ce9ca-0c46-41b0-b211-053939eed9fc                 running        az1  10.10.12.25   vm-4242f172-cef8-4939-bb48-31efe4c87feb  micro        true
clock_global/2bfe6bc2-26b4-49dd-90d6-9c8aefdc27fc                   running        az1  10.10.12.32   vm-afb2ba2b-0a63-4ee0-857c-2dc692ce6370  medium.disk  true
cloud_controller/6ceebbc2-19a2-40d5-8ce1-7250d10793b6               running        az1  10.10.12.28   vm-f302b49f-3b41-47bc-913a-81ec345ce93c  medium.disk  true
cloud_controller_worker/a1bcd628-300e-4996-b3a3-c665a8ec8834        running        az1  10.10.12.33   vm-8147b18a-320d-4924-8902-7b6005beb9b8  micro        true
credhub/268c88a4-f515-4748-b25a-8addf5c9c209                        running        az1  10.10.12.45   vm-3b2b624e-6eb8-49c7-ab47-6e0e96ce7136  large        true
diego_brain/62124476-f15f-4c76-b8ac-e5caf1ae76a7                    running        az1  10.10.12.29   vm-ba3734af-200e-4ee5-9d58-fb9f532a2b3d  small        true
diego_cell/4e401ed9-e6d3-4c1a-87fc-838d37a70747                     running        az1  10.10.12.34   vm-c914d5c0-a36b-424d-ab8c-88baab67e5de  large.disk   true
                                                                                        10.10.14.41
diego_cell/5542bdbc-4f54-4d1b-8d43-c2075a2d123d                     running        az2  10.10.12.38   vm-572f459d-81ca-49b6-8c93-448dc9e8e6ee  large.disk   true
                                                                                        10.10.14.43
diego_cell/718a3bd2-d5ee-4898-9694-7c822057352f                     running        az2  10.10.12.40   vm-23e5f33a-271b-4bfe-a610-c5d95a2d62d0  large.disk   true
                                                                                        10.10.14.44
diego_cell/84fc48e7-52d7-42ee-8306-da176fc2e571                     running        az1  10.10.12.36   vm-7ba60bfd-3504-45d3-869f-2803a2212cd0  large.disk   true
                                                                                        10.10.14.42
                                                                                   
```
now after pushing an app, you can check the networking to DB-network while ssh into the app container.
```
➜  ~ cf ssh ext
vcap@ddf9eabd-77cf-4d70-7139-afcb:~$ ping 10.10.14.32
PING 10.10.14.32 (10.10.14.32) 56(84) bytes of data.
64 bytes from 10.10.14.32: icmp_seq=1 ttl=63 time=0.903 ms
64 bytes from 10.10.14.32: icmp_seq=2 ttl=63 time=0.254 ms

```
