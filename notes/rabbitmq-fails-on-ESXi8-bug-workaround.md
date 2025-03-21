## workaround for rabbitmq for TAS failure due to ESXi 8.0.2 bug.
this document addresses how to apply the Option 2 sugggested by [KB](https://knowledge.broadcom.com/external/article/390336/workaround-for-all-rabbitmq-running-on-v.html) 
```
Option 2: Modify the VMX File Settings

Edit the VM's .vmx configuration file and add the following parameters:

featMask.vm.cpuid.AVX512F="Max:0"
featMask.vm.cpuid.AVX512FP16="Max:0"
Perform a full power cycle of the VM (shut down and restart) for the changes to take effect.
```
## How to apply

1. disable bosh resurrection from opsman VM.

```
bosh update-resurrection off
```
2. locate VM name (VM CID)
```
bosh -d service-instance_1d5b13b2-a9ff-481c-b2c9-62f8db74887f vms
Using environment '192.168.0.55' as client 'ops_manager'

Task 14699. Done

Deployment 'service-instance_1d5b13b2-a9ff-481c-b2c9-62f8db74887f'

Instance                                              Process State  AZ   IPs           VM CID                                                                           VM Type  Active  Stemcell
rabbitmq-server/91bd4dd9-e2e4-43b0-a371-749822c5048f  failing        AZ1  192.168.0.75  rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_b7a38bbaa19b  large    true    bosh-vsphere-esxi-ubuntu-jammy-go_agent/1.708
rabbitmq-server/9995b4a7-0675-409d-8482-1b979cdb9ded  running        AZ1  192.168.0.76  rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4  large    true    bosh-vsphere-esxi-ubuntu-jammy-go_agent/1.708
rabbitmq-server/eb69195e-f0c3-4cd5-b01e-c3e60b36bf93  failing        AZ1  192.168.0.74  rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_ece9a71fa9fa  large    true    bosh-vsphere-esxi-ubuntu-jammy-go_agent/1.708
```

3. on vsphere UI, find the rabbitmq VM info (https://knowledge.broadcom.com/external/article?legacyId=1003748)

3-a. find vmx location in datastore: Right-click the entry for the virtual machine > Edit Settings > VM Options tab> General Options> VM Config File.
Note: The location of the .vmx file displayed here takes the form [server:datastore] directory/vm.vmx . Interpret the full path to this file on a server as /vmfs/volumes/datastore/directory/vm.vmx .
for example: 
[ssd_1tb] rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4/rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vm

3-b. find ESXi where each rabbitmq VM is running on.


4. ssh into the ESXi and goto the VM folder
```
ssh root@ESXI_IP

[root@localhost:~] cd /vmfs/volumes/ssd_1tb/rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4
[root@localhost:/vmfs/volumes/62b6444c-d40ec6d8-c6c5-f07959379ede/rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4]
[root@localhost:/vmfs/volumes/62b6444c-d40ec6d8-c6c5-f07959379ede/rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4] ll
total 10145152
drwxr-xr-x    1 root     root         77824 Mar 21 02:36 .
drwxr-xr-t    1 root     root         94208 Mar 21 03:09 ..
-rw-r--r--    1 root     root         51200 Mar  5 03:13 env.iso
-rw-r--r--    1 root     root          7710 Mar  5 03:13 env.json
-rw-------    1 root     root     17179869184 Mar 21 03:12 ephemeral_disk-flat.vmdk
-rw-------    1 root     root           534 Mar 21 02:36 ephemeral_disk.vmdk
-rw-r--r--    1 root     root           677 Mar  5 03:13 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4-7cc630f0.hlog
-rw-------    1 root     root     8589934592 Mar 21 02:35 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4-eae93ad2.vswp
-rw-------    1 root     root     193613824 Mar 21 03:12 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4-sesparse.vmdk
-rw-------    1 root     root         74232 Mar 21 02:36 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.nvram
-rw-------    1 root     root           616 Mar 21 02:36 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmdk
-rwxr-xr--    1 root     root           268 Mar  5 03:13 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmsd
-rwxr-xr-x    1 root     root          3897 Mar 21 02:35 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx
-rw-------    1 root     root             0 Mar  5 03:13 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx.lck
-rwxr-xr-x    1 root     root          3897 Mar 21 02:35 rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx~
-rw-------    1 root     root      84934656 Mar 21 02:35 vmx-rabbitmq-server_serv-26d7a4e900e51cf77586c33434535bf2291f711f-1.vswp
```

5. Edit the VM's .vmx configuration file and add the following parameters
make sure back up the file and modify.
```
cp rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx.orig

vi rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx

...
...
featMask.vm.cpuid.AVX512F="Max:0"
featMask.vm.cpuid.AVX512FP16="Max:0"
```

and watch the file to see if the changes is maintained until the target vm is booted up in the next step
```
watch diff rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx.orig
--- rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx
+++ rabbitmq-server_service-instance-1d5b13b2-a9ff-481c-b2c9-62f8db748_aa5d231d98a4.vmx.orig
@@ -94,4 +94,3 @@
 scsi0:2.mode = "independent-persistent"
 scsi0:2.present = "TRUE"
 scsi0:2.redo = ""
-featMask.vm.cpuid.AVX="Max:0"
```

6. Perform a full power cycle of the VM (Hard Stop and power on) for the changes to take effect
   WARNIG: just powering  off will revert the vmx change back to original. 
```
vCenter > rabbitmq VM > Actions> Power > Hard Stop
vCenter > rabbitmq VM > Actions> Power > Power on
```

7. verify if the change is applied to rabbitmq VM

```
rabbitmq-server/9995b4a7-0675-409d-8482-1b979cdb9ded:~$ cat /proc/cpuinfo
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 62
model name	: Intel(R) Xeon(R) CPU E5-2667 v2 @ 3.30GHz
stepping	: 4
microcode	: 0x42e
cpu MHz		: 3312.162
cache size	: 25600 KB
physical id	: 0
siblings	: 1
core id		: 0
cpu cores	: 1
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 13
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx rdtscp lm constant_tsc arch_perfmon nopl xtopology tsc_reliable nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave rdrand hypervisor lahf_lm cpuid_fault pti ssbd ibrs ibpb stibp fsgsbase tsc_adjust smep arat md_clear flush_l1d arch_capabilities
bugs		: cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit mmio_unknown retbleed bhi
bogomips	: 6624.32
clflush size	: 64
cache_alignment	: 64
address sizes	: 43 bits physical, 48 bits virtual
power management:

rabbitmq-server/9995b4a7-0675-409d-8482-1b979cdb9ded:~$ cat /proc/cpuinfo | grep avx512f
rabbitmq-server/9995b4a7-0675-409d-8482-1b979cdb9ded:~$
```
