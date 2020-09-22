https://starkandwayne.com/blog/how-to-lock-vcap-password-for-bosh-vms/

```
$ apt install whoi
$ mkpasswd -s -m sha-512
Password: changeme
$6$GFsoUYxb48$1/k2bvkpoo3pEf8963nqJOWwWTbxeEPc9aqNRBmFJpzjBNwpwrXI6vcLuGcQOxgGoIonsJu84.UVor/gMiFbt/
```

Example of setting a password in vm_types in cloud-config.yml
``` 
vm_types:
- name: default
  env:
    bosh:
      password: $6$GFsoUYxb48$1/k2bvkpoo3pEf8963nqJOWwWTbxeEPc9aqNRBmFJpzjBNwpwrXI6vcLuGcQOxgGoIonsJu84.UVor/gMiFbt/

```
or  Example of setting a password for a specific instance:
```
 instance_groups:
 - name: my-instance-name
   env:
    bosh:
     password: HASH of the password

```



