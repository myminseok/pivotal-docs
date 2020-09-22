## ref
https://docs.cloudfoundry.org/devguide/deploy-apps/large-app-deploy.html

## tas tile config: https://docs.pivotal.io/application-service/2-10/operating/configure-pas.html#appdevctrl-config
- Maximum file upload size: max droplet size(2048MB)

## minimun_staging_disk_md
- cloud-controller

## ssh
/var/vcap/packages/runc/bin/runc --root /run/containerd/runc/garden/ exec -t <containerid> /bin/bash
  
