#!/bin/bash
export TARGET_DS='cf-f30f16d0a030d67be63a'
bosh -d $TARGET_DS ssh diego_cell -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $TARGET_DS ssh clock_global -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $TARGET_DS ssh cloud_controller -c 'dig autoscale.sys.lab.pcfdemo.net'
bosh -d $TARGET_DS ssh cloud_controller_worker -c 'dig autoscale.sys.lab.pcfdemo.net'
