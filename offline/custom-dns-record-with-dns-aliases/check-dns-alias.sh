#!/bin/bash

bosh -d cf-f30f16d0a030d67be63a ssh clock_global -c 'dig api.sys.lab.pcfdemo.net'
bosh -d cf-f30f16d0a030d67be63a ssh diego_cell -c 'dig api.sys.lab.pcfdemo.net'
