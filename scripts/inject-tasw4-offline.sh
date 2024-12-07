# This is an alternative script to 'winfs-injector-0.25.0' for air-gapped environment. 
# Downloading all the image layers from Docker and Microsoft into the blobs directory as a tgz is originally done by './src/code.cloudfoundry.org/hydrator/bin/hydrate' 
# but it requires internet outbound connection as the hydrator is hardcoded to use https://registry.hub.docker.com
# this script does not use hydrate but does the same with script with pre-download resources
# tested for pas-windows-4.0.24-build.2.pivotal only. 
# On Windows workstation > Download docker resources 
# 1) install docker desktop for windows(https://docs.docker.com/desktop/setup/install/windows-install/#what-to-know-before-you-install)
# 2) download docker image
#    docker pull cloudfoundry/windows2016fs:2019.0.165 
#    docker save cloudfoundry/windows2016fs:2019.0.165 -o windows2016fs_2019_0_165_docker.tar 
#    gzip < windows2016fs_2019_0_165_docker.tar > windows2016fs_2019_0_165_docker.tgz
# 3) copy windows2016fs_2019_0_165_docker.tgz  to Ubuntu workstation under /tmp/windowsfs/windows2016fs_2019_0_165_docker.tgz
# On Linux/Mac workstation (such as Opsmanager VM)
# 1) Install tools on workstation 
# - apt install zip
# - bosh cli (https://github.com/cloudfoundry/bosh-cli/releases) (opsmanager VM aleady has)
# 2) Download https://s3.amazonaws.com/windows2019fs-release/fc5fd197-4d20-4c24-5d12-d57e93a4f8f0 to /tmp/windowsfs/
# 3) pas-windows-4.0.24-build.2.pivotal


#!/usr/bin/env bash
set -e
set -u
set -x
set -o pipefail


# Crack the tile open into the tasw directory
#tasw_tiles=(./pas-windows-*.pivotal)
tasw_tiles='pas-windows-4.0.24-build.2.pivotal'
tasw_tile="${tasw_tiles=[0]}"
unzip "$tasw_tile" -d ./tasw


pushd ./tasw/embed/windowsfs-release
if [ `uname` == "Linux" ]; then
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -oP '\d*\.\d*\.\d*')"
else
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -o '\d*\.\d*\.\d*')"
fi
popd


## cloudfoundry/windows2016fs:2019.0.165 saved as tar via docker cli, then it has the same metadata file which is supposed to be created by hydrator
## 1) diffIds config file
## windows2016fs_2019_0_165_docker.tar > blobs/sha256/445959e7dd961ab4a53a65ace9e93cbef4a4a1136fc94c2fc8dd86b83b1abd72
## downloader provides diffIds https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## 2) manifest that points to diffIds config file above
## windows2016fs_2019_0_165_docker.tar > blobs/sha256/d46d2a79bfc8da927ab0c1ecf1c32468c1a6309d4b44415e16793363e48426b1
## downloader provides layers https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## 3) windows2016fs_2019_0_165_docker.tar > index.json that points to manifest
## 4) windows2016fs_2019_0_165_docker.tar > oci-layout

# Gzip the docker tar file.
pushd ./tasw/embed/windowsfs-release
mkdir -p ./blobs/windows2019fs
cp /tmp/windowsfs/windows2016fs_2019_0_165_docker.tgz ./blobs/windows2019fs/windows2016fs-2019.0.165.tgz
#gzip < /tmp/windowsfs/windows2016fs_2019_0_165_docker.tar > ./blobs/windows2019fs/windows2016fs-2019.0.165.tgz

# Update the bosh blobstore to be local and not use S3
## prerequisites, Download  https://s3.amazonaws.com/windows2019fs-release/fc5fd197-4d20-4c24-5d12-d57e93a4f8f0 under /tmp/windowsfs/
cat << EOF > ./config/final.yml
---
name: windows2019fs
blobstore:
  provider: local
  options:
    blobstore_path: /tmp/windowsfs
EOF

# Create a dev release
bosh create-release --name=windows2019fs --version=$TAG --force --tarball "../../releases/windows2019fs-$TAG.tgz"
popd

# Remove our working content so we don't bloat the tile
pushd ./tasw
rm -rf ./embed

# Add the windows2019fs release to the tile's list of releases
cat << EOF > /tmp/metadata-ops.yml
- type: replace
  path: /releases/-
  value: 
    file: windows2019fs-$TAG.tgz
    name: windows2019fs
    version: $TAG
EOF
bosh interpolate ./metadata/metadata.yml --ops-file /tmp/metadata-ops.yml > ./metadata/metadata-new.yml
mv -f ./metadata/metadata-new.yml ./metadata/metadata.yml

# Repackage the tile with rootfs fully hydrated
zip -r "../pas-windows-injected.pivotal" .
popd

# Cleanup
rm -rf ./tasw
rm /tmp/metadata-ops.yml
