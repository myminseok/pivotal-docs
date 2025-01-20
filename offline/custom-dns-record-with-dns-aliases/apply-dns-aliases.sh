#!/bin/bash

bosh -d cf-f30f16d0a030d67be63a scp ./aliases.json clock_global:/tmp/aliases.json
bosh -d cf-f30f16d0a030d67be63a ssh clock_global -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'

bosh -d cf-f30f16d0a030d67be63a scp ./aliases.json diego_cell:/tmp/aliases.json
bosh -d cf-f30f16d0a030d67be63a ssh diego_cell -c 'sudo mkdir -p /var/vcap/jobs/my-aliases/dns/; sudo cp /tmp/aliases.json /var/vcap/jobs/my-aliases/dns/; sudo /var/vcap/bosh/bin/monit restart bosh-dns'