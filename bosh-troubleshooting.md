

## Get bbr key for director VM
https://github.com/myminseok/pivotal-docs/blob/master/platform-automation/bbr-backup.md#get-bbr-key


## Cancel queued tasks in bosh director
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

