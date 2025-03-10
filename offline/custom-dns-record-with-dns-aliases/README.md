
How to add customer DNS records via BOSH DNS aliases
https://knowledge.broadcom.com/external/article/298060/how-to-add-customer-dns-records-via-bosh.html

Listed below are some scenarios you could consider using this workaround:
- The application team wants to add some DNS records for testing while they have not yet got approval to change in their external DNS servers (configured in BOSH tile).
- There is an issue in the customer networking layer, typically the Load Balancer (LB), which could cause app-to-app communication errors if the route is through LB.
- As a workaround on this issue, you can try bypass LB by resolving destination app's route to Gorouter IP.

#### for TAS tile
0. ssh into bosh enabled VM (such as opsmanager)
1. edit [aliases.json](aliases.json)
2. find target deployment.
```
bosh ds | grep cf-
```
3. edit [apply-dns-aliases.sh](apply-dns-aliases.sh) and apply to target VMs
```
export TARGET_DS='pas-windows-7a03715687d2f7514359'
```
4. edit [check-dns-alias.sh](check-dns-alias.sh) and execute to verify
5. After testing, you should remove this workaround and continue with the permanent change in external DNS servers. [remove-dns-aliases.sh](remove-dns-aliases.sh)

#### for windows tile
it would required for 'install HWC buildpack errand'
0. ssh into bosh enabled VM (such as opsmanager)
1. edit [aliases.json](aliases.json)
2. find target deployment.
```
bosh ds | grep windows
```
3. edit [apply-win.sh](apply-win.sh) and apply to target VMs
```
export TARGET_DS='cf-xxxx'
```
4. edit [check-win.sh](check-win.sh) and execute to verify
5. After testing, you should remove this workaround and continue with the permanent change in external DNS servers. [remove-win.sh](remove-win.sh)
