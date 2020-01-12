

## integrate opsman UI with LDAP Authentication
- https://docs.pivotal.io/platform/ops-manager/2-6/vsphere/config.html#ldap
- "LDAP RBAC Admin Group Name": for opsman admin from LDAP
- "Group Search Base", "Group Search Filter": for opsman users from LDAP

## Manage Roles with LDAP Authentication (RBAC)
- https://docs.pivotal.io/pivotalcf/2-6/opsguide/config-rbac.html


```
uaac group map LDAP-GROUP --name 'OPSMAN-SCOPE'
=> !!! LDAP-GROUP should be FQDN, not CN(user) only

ex)
uaac group map  "OU=OpsmanAdminGroup,DC=myldap,DC=com" --name opsman.full_control

```

## test ldap filter:
- https://community.pivotal.io/s/article/Configuring-LDAP-Integration-with-Pivotal-Cloud-Foundry


