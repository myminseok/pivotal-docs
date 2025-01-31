
How to add customer DNS records via BOSH DNS aliases
https://knowledge.broadcom.com/external/article/298060/how-to-add-customer-dns-records-via-bosh.html

Listed below are some scenarios you could consider using this workaround:
The application team wants to add some DNS records for testing while they have not yet got approval to change in their external DNS servers (configured in BOSH tile).
There is an issue in the customer networking layer, typically the Load Balancer (LB), which could cause app-to-app communication errors if the route is through LB. To troubleshoot this issue, you can try bypass LB by resolving destination app's route to Gorouter IP.
Note: After testing, you should remove this workaround and continue with the permanent change in external DNS servers.
