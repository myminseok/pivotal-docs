#!/bin/bash

bosh -d cf-f30f16d0a030d67be63a ssh clock_global -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'
bosh -d cf-f30f16d0a030d67be63a ssh diego_cell -c 'sudo rm -rf /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'