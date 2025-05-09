
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
 [[ $line == "#"* ]] &&  echo "skip $line" && continue
 echo "cancel task $line"
 bosh cancel-task $line

done < bosh-tasks.txt
```
## Cancel bosh tasks (debug director)

#### Get bbr key for director VM
https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/bbr-backup.md#get-bbr-key


#### Cancel queued tasks in bosh director
https://knowledge.broadcom.com/external/article/293826/how-to-cancel-all-queued-bosh-tasks-usin.html
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

