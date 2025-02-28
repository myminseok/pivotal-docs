#!/bin/bash
export DS='cf-f30f16d0a030d67be63a'
bosh -d $DS ssh diego_cell -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $DS ssh clock_global -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $DS ssh cloud_controller -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $DS ssh cloud_controller_worker -c 'dig autoscale.sys.lab.pcfdemo.net'
