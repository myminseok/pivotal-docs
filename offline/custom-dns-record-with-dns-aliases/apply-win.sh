#!/bin/bash
export TARGET_DS='pas-windows-472cf4dae4f993d5843e'
bosh -d $TARGET_DS scp ./aliases.json windows_diego_cell:/tmp/aliases.json
bosh -d $TARGET_DS ssh windows_diego_cell -c 'rmdir c:\var\vcap\jobs\my-aliases /s /q'
bosh -d $TARGET_DS ssh windows_diego_cell -c 'mkdir c:\var\vcap\jobs\my-aliases && mkdir c:\var\vcap\jobs\my-aliases\dns && copy c:\tmp\aliases.json c:\var\vcap\jobs\my-aliases\dns'
bosh -d $TARGET_DS ssh windows_diego_cell -c 'powershell restart-service bosh-dns-windows && powershell restart-service bosh-dns-nameserverconfig-windows'
