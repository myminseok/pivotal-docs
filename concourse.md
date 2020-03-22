## Concourse concept
* concourse architecture: https://concourse-ci.org/concepts.html


# Architecture: 
- https://docs.pivotal.io/p-concourse/4-x/index.html
- https://docs.pivotal.io/pivotalcf/2-5/plan/control.html


# Docs
- https://concourse-ci.org/
- http://concoursetutorial.com
- https://www.docker.com/get-started
- slides: https://github.com/myminseok/slides/blob/master/Concourse-workshop-all-in-one.pdf

## Blogs
https://medium.com/concourse-ci


# Demo-pipelines: 
- https://github.com/starkandwayne/concourse-tutorial.git
- resource: docker-image > https://github.com/concourse/docker-image-resource > source configuration, in, out
- docker-image, git, s3, time
- https://github.com/concourse/git-resource

## download docker image: pivotalcf/pivnet-resource
```
docker pull pivotalcf/pivnet-resource
docker save pivotalcf/pivnet-resource -o docker-image-pivotalcf_pivnet-resource
docker load -i docker-image-pivotalcf_pivnet-resource
docker tag pivotalcf/pivnet-resource harbor.local/pivotalcf/pivnet-resource

/etc/docker/daemon.json => insecure... harbor.local
systemctl restart docker.service

docker login harbor.local -u -p 
docker push harbor.local/pivotalcf/pivnet-resource

```

## Caching feature
- https://medium.com/concourse-ci/suspicious-volume-usage-on-workers-72131cff9bfd
- https://medium.com/concourse-ci/concourse-resource-volume-caching-7f4eb73be1a6

## Monitoring
https://metrics.concourse-ci.org/d/000000007/concourse?refresh=1m&orgId=1


