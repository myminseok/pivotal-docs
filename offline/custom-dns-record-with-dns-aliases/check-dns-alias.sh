#!/bin/bash
export TAS='cf-f30f16d0a030d67be63a'
bosh -d $TAS ssh clock_global -c 'dig api.sys.lab.pcfdemo.net'
bosh -d $TAS ssh diego_cell -c 'dig api.sys.lab.pcfdemo.net'
