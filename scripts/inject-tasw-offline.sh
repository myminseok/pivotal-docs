#!/usr/bin/env bash
set -e
set -u
set -x
set -o pipefail


# Alternative to winfs-injector-0.25.0 for air-gapped environment

# Prerequisites
## tested for pas-windows-4.0.24-build.2.pivotal
## imgpkg copy -i cloudfoundry/windows2016fs:2019.0.165 --to-tar /tmp/windowsfs/windows2016fs:2019.0.165.tar
## Download https://s3.amazonaws.com/windows2019fs-release/fc5fd197-4d20-4c24-5d12-d57e93a4f8f0 to /tmp/windowsfs/


# Crack the tile open into the tasw directory
#tasw_tiles=(./pas-windows-*.pivotal)
tasw_tiles='pas-windows-4.0.24-build.2.pivotal'
tasw_tile="${tasw_tiles=[0]}"
unzip "$tasw_tile" -d ./tasw

# Download all the image layers from Docker and Microsoft into the blobs directory as a tgz
# originally, this should be done by './src/code.cloudfoundry.org/hydrator/bin/hydrate' 
# but it requires internet outbound connection as the hydrator is hardcoded to use https://registry.hub.docker.com
# Following code is alternative for air-gapped env and does the samething with hydrate but no need iternet connection.
## as prerequisites, download docker image from internet and upload to internal repo as following commands:
## imgpkg copy -i cloudfoundry/windows2016fs:2019.0.165 --to-tar /tmp/windowsfs/windows2016fs:2019.0.165.tar
## imgpkg copy --tar windows2016fs:2019.0.165.tar --to-repo INTERRNAL_DOCKER_REPO/cloudfoundry/windows2016fs

pushd ./tasw/embed/windowsfs-release
if [ `uname` == "Linux" ]; then
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -oP '\d*\.\d*\.\d*')"
else
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -o '\d*\.\d*\.\d*')"
fi
# ./src/code.cloudfoundry.org/hydrator/bin/hydrate download -image cloudfoundry/windows2016fs -tag "$TAG" -outputDir ./blobs/windows2019fs
popd

mkdir -p /tmp/blobs/windows2019fs/blobs/sha256
tar xvf /tmp/windowsfs/windows2016fs:2019.0.165.tar -C /tmp/blobs/windows2019fs/blobs/sha256

FILES=$(ls -al /tmp/blobs/windows2019fs/blobs/sha256/*.tar.gz| awk '{print $9}')
for i in $FILES; do 
  NEW_NAME=$(echo $i| sed 's/sha256-//g' | sed 's/.tar.gz//g')
  mv $i $NEW_NAME
done

# creates metadata file that should be created by hydrator
cat << EOF > /tmp/blobs/windows2019fs/index.json
{"schemaVersion":2,"manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:817f551aeb16ca932aa3ee7b09e8e818042c0650c87711faae17e4900b5e6f5b","size":5416,"platform":{"architecture":"amd64","os":"windows"}}]}
EOF

# creates metadata file that should be created by hydrator
cat << EOF > /tmp/blobs/windows2019fs/oci-layout
{"imageLayoutVersion":"1.1.0"}
EOF

# tar release and place under bosh release
pushd /tmp/blobs/windows2019fs
tar zcvf ../windows2016fs-$TAG.tgz *
popd

pushd ./tasw/embed/windowsfs-release
mkdir -p ./blobs/windows2019fs
mv /tmp/blobs/windows2016fs-$TAG.tgz ./blobs/windows2019fs
rm -rf /tmp/blobs


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
#rm -rf ./tasw
#rm /tmp/metadata-ops.yml
