- guide: https://github.com/minio/minio-boshrelease
- bosh release: https://bosh.io/releases/github.com/minio/minio-boshrelease?all=1

```
# download minio-boshrelease deployment
 wget https://github.com/minio/minio-boshrelease/archive/master.zip

```

# download bosh release
https://bosh.io/releases/github.com/minio/minio-boshrelease?all=1
```
wget -O minio-boshrelease https://bosh.io/d/github.com/minio/minio-boshrelease?v=2019-04-09T01-22-30Z
bosh upload-release minio-boshrelease
```
# download stemcell
https://bosh.io/stemcells/bosh-vsphere-esxi-ubuntu-trusty-go_agent
```
wget https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-trusty-go_agent?v=3586.96
bosh upload-stemcell

```

# manifest.yml편집
```
bosh cloud-config 참고해서 편집.

./manifests/manifest-dist-example.yml

deploy.sh

bosh deploy -d minio manifests/manifest-dist-example.yml \
    -v minio_deployment_name=minio \
    -v minio_accesskey=admin \
    -v minio_secretkey=---


bosh vms

브라우져: https://<IP>:9000

```







