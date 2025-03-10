#!/bin/bash

export TARGET_DS='cf-xxxx'

bosh -d $TARGET_DS ssh clock_global -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TARGET_DS scp ./aliases.json clock_global:/tmp/aliases.json
bosh -d $TARGET_DS ssh clock_global -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

bosh -d $TARGET_DS ssh diego_cell -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TARGET_DS scp ./aliases.json diego_cell:/tmp/aliases.json
bosh -d $TARGET_DS ssh diego_cell -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

bosh -d $TARGET_DS ssh cloud_controller -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TARGET_DS scp ./aliases.json cloud_controller:/tmp/aliases.json
bosh -d $TARGET_DS ssh cloud_controller -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

bosh -d $TARGET_DS ssh cloud_controller_worker -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TARGET_DS scp ./aliases.json cloud_controller_worker:/tmp/aliases.json
bosh -d $TARGET_DS ssh cloud_controller_worker -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

export TARGET_DS='appMetrics-xxxx'
bosh -d $TARGET_DS ssh db-and-errand-runner -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TARGET_DS scp ./aliases.json db-and-errand-runner:/tmp/aliases.json
bosh -d $TARGET_DS ssh db-and-errand-runner -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

