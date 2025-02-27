#!/bin/bash

export TAS='cf-f30f16d0a030d67be63a'

bosh -d $TAS ssh clock_global -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TAS scp ./aliases.json clock_global:/tmp/aliases.json
bosh -d $TAS ssh clock_global -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

bosh -d $TAS ssh diego_cell -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TAS scp ./aliases.json diego_cell:/tmp/aliases.json
bosh -d $TAS ssh diego_cell -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

bosh -d $TAS ssh cloud_controller -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TAS scp ./aliases.json cloud_controller:/tmp/aliases.json
bosh -d $TAS ssh cloud_controller -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

bosh -d $TAS ssh cloud_controller_worker -c 'sudo rm -rf /tmp/aliases.json'
bosh -d $TAS scp ./aliases.json cloud_controller_worker:/tmp/aliases.json
bosh -d $TAS ssh cloud_controller_worker -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
