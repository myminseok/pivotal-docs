
In [Control Plane Architecture](control-plane.md) , security topics are scattered and it is hard to understand the relationship among each areas. this document covers all security topics in one place and helps to understand overall concepts.


# Overall security in reference architecture 
* overall architure(TBD): access boundary, uaa topology, isolation segments
* Understanding Cloud Foundry Security(isolation segments in PAS): https://docs.pivotal.io/pivotalcf/2-4/concepts/security.html



# User management & integration
* UAA concept: https://docs.pivotal.io/pivotalcf/2-4/uaa/uaa-overview.html
* user management on PAS: 
- using uaac: https://docs.pivotal.io/pivotalcf/2-4/uaa/uaa-user-management.html
- using cf cli: https://docs.pivotal.io/pivotalcf/2-4/adminguide/cli-user-management.html
* user management on opsmanager https://docs.pivotal.io/pivotalcf/2-4/customizing/opsman-users.html
* user management on concourse https://docs.pivotal.io/p-concourse/4-x/authenticating.html
* user management on credhub with UAA: http://credhub-api.cfapps.io/version/2.1/#authentication
* hands on (TBD)

# Credhub & UAA integration
* co-locate credhub with concourse(web) https://github.com/myminseok/pivotal-docs/blob/master/concourse-with-credhub.md
* concourse with PAS auth https://github.com/myminseok/pivotal-docs/blob/master/concourse_with_cf_auth.md
* credhub co-location with bosh, credhub cluster https://github.com/pivotal-cf/credhub-release/tree/master/docs

# Networking 
* understanding container to container networking with app service discovery( internal domains): https://docs.pivotal.io/pivotalcf/2-4/concepts/understand-cf-networking.html
* (reference) vxlan, overlay network( concept & diagram)  :http://blog.nigelpoulton.com/demystifying-docker-overlay-networking/

# Container security
understanding container security: https://docs.pivotal.io/pivotalcf/2-4/concepts/container-security.html
* hardening

# PCF security engineering
* PCF security engineering documentation: https://docs.pivotal.io/pivotalcf/2-2/security/process/security-lifecycle.html
* release lifecycle flowchart:  https://github.com/pivotal-cf/docs-pcf-security/blob/2.2/images/triage-flowchart.png

# Credhub related
* credhub api docs  http://credhub-api.cfapps.io/version/2.1/
* credhub service broker scenario on PAS: https://content.pivotal.io/blog/enterprise-architects-its-time-to-learn-how-the-credhub-service-broker-applies-the-principle-of-least-privilege-to-your-secrets
* credhub oss repo: https://github.com/cloudfoundry-incubator/credhub
* credhub documentation(roadmap, oss): https://github.com/cloudfoundry-incubator/credhub/tree/master/docs

