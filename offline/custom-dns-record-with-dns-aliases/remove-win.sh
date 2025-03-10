#!/bin/bash
export TARGET_DS='pas-windows-7a03715687d2f7514359'
bosh -d $TARGET_DS ssh windows_diego_cell -c 'rmdir c:\var\vcap\jobs\my-aliases /s /q'
bosh -d $TARGET_DS ssh windows_diego_cell -c 'powershell restart-service bosh-dns-windows && powershell restart-service bosh-dns-nameserverconfig-windows'