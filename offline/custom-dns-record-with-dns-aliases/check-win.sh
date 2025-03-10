#!/bin/bash
export TARGET_DS='pas-windows-7a03715687d2f7514359'
bosh -d $TARGET_DS ssh windows_diego_cell -c 'nslookup api.sys.lab.pcfdemo.net'