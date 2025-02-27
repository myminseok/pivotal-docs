#!/bin/bash
export TAS='cf-f30f16d0a030d67be63a'
bosh -d $TAS ssh clock_global -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
bosh -d $TAS ssh diego_cell -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
