#!/bin/bash
export TARGET_DS='cf-f30f16d0a030d67be63a'
bosh -d $TARGET_DS ssh clock_global -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
bosh -d $TARGET_DS ssh diego_cell -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
bosh -d $TARGET_DS ssh cloud_controller -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
bosh -d $TARGET_DS ssh cloud_controller_worker -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
