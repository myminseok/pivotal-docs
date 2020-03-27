
## Cancel bosh tasks with bosh command
http://mywiki.wooledge.org/BashFAQ/001

```
bosh tasks | grep -i "queued" | awk '{print $1}' > bosh-tasks.txt

cat bosh-tasks.txt


```
bosh-cancel-tasks.sh
```
#!/bin/bash

while IFS= read -r line; do
 if [[ "$line" == "#"* ]]; then
   continue
 fi
 bosh cancel-task $line

done < bosh-tasks.txt
```
## Cancel bosh tasks (debug director)

#### Get bbr key for director VM
https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/bbr-backup.md#get-bbr-key


#### Cancel queued tasks in bosh director
https://community.pivotal.io/s/article/How-to-Cancel-All-Queued-BOSH-Tasks-Using-director-ctl
```

# ssh into bosh director VM

sudo su -

/var/vcap/jobs/director/bin/console

irb(main):001:0> Bosh::Director::Models::Task.where(state: "queued").count

# queued —> cancelling 
irb(main):002:0> Bosh::Director::Models::Task.where(state: "queued").update(state: "cancelling")

# cancelling —> done
irb(main):002:0> Bosh::Director::Models::Task.where(state: "cancelling").update(state:"done")

```

