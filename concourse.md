
# architecture: 
- https://docs.pivotal.io/p-concourse/4-x/index.html
- https://docs.pivotal.io/pivotalcf/2-5/plan/control.html


# docs
- https://concourse-ci.org/
- http://concoursetutorial.com
- https://www.docker.com/get-started
- slides: https://github.com/myminseok/slides/blob/master/Concourse-workshop-all-in-one.pdf

# demo-pipelines: 
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
