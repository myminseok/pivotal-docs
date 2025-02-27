#!/bin/bash
export TAS='cf-f30f16d0a030d67be63a'
bosh -d $TAS ssh clock_global -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $TAS ssh diego_cell -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $TAS ssh cloud_controller -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $TAS ssh cloud_controller_worker -c 'dig autoscale.sys.lab.pcfdemo.net'
