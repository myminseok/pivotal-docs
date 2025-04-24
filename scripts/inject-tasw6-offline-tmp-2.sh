# README
#
# This is an alternative script to 'winfs-injector-0.26.0' for air-gapped environment. 
# 'winfs-injector' uses `hydrator` internally to download all windowsfs layers and dependencies from internet and packages to pivotal tile. 
# this script does not require internet outbound connection as it doesnot use hydrate but does the same with script with pre-downloaded resources
# should support tas-windows-6.0.X-build.2.pivotal(tested for pas-windows-6.0.5-build.2.pivotal, pas-windows-6.0.6-build.2.pivotal only)
# tested on Linux VM or Mac OS, Centos 9
#
# This script will inject windows2016fs:2019.0.167 which is default dependency from windows tile. 
#
# Prerequisites
#
# Install tools on workstation 
# - install go (latest)
# - install zip (latest)
# - install git (latest)
# - bosh cli (latest, tested on version 7.8.2) (https://github.com/cloudfoundry/bosh-cli/releases)
# - imgpkg cli (latest, tested on version 0.43.1) (https://carvel.dev/imgpkg/)
#
# Download resources on workstation
# 1) pas-windows-6.0.x-build.2.pivotal
# 2) imgpkg copy -i cloudfoundry/windows2016fs:2019.0.167 --to-tar /tmp/windowsfs/windows2016fs_2019.0.167.tar
# NOTE: golang-1.22-windows from pas-windows-6.0.5-build.2.pivotal will be reused. so no need to download from s3.
#
# How to Run
# WARNING: for complete offline testing, delete bosh local cache for complete offline testing : rm -rf ~/.bosh
# 1) locate files: 
# CURRENT_DIRECTORY/pas-windows-6.0.5-build.2.pivotal
# CURRENT_DIRECTORY/inject-tasw6-offline.sh 
# /tmp/windowsfs/windows2016fs_2019.0.167.tar
# 2) update this script for source file version: tasw_tiles='pas-windows-6.0.5-build.2.pivotal'
# 3) run this script. then output will be created under current directory something line "injected-pas-windows-6.0.6-build.2.pivotal"


## this script will consume around max 9GB at ~/.bosh folder

#!/usr/bin/env bash
set -e
set -u
set -x
set -o pipefail

tasw_tile='pas-windows-6.0.5-build.2.pivotal'

# repackage all the image layers from pre-downloaded resources under /tmp/windowsfs/
## fetch target windowsfs version
## manually modifying version will break "bosh create" step(unable to find required files)
## TAG=2019.0.167
pushd /tmp/tasw/embed/windowsfs-release
if [ `uname` == "Linux" ]; then
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -oP '\d*\.\d*\.\d*')"
else
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -o '\d*\.\d*\.\d*')"
fi
popd


pushd /tmp/tasw/embed/windowsfs-release
# modify meta to reuse golang-1.22-windows from pas-windows-6.0.5-build.2.pivotal instead of download from s3.
# and it should also be matched with ./.final_builds/packages/golang-1.22-windows/index.yml
cat << EOF > ./packages/golang-1.22-windows/spec.lock
name: golang-1.22-windows
fingerprint: d58174aba07bdc1913cba21648c64b8716d80b6be58bba2b53a37599aa806a0c
EOF

# Update the bosh blobstore to be local and not use S3 (https://s3.amazonaws.com/windows2019fs-release/1d3bd634-0e80-4a91-7970-5eee8b0d6ce2)
cat << EOF > ./config/final.yml
---
name: windows2019fs
blobstore:
  provider: local
  options:
    blobstore_path: /tmp/windowsfs
EOF

mkdir -p /tmp/windowsfs
# Create a dev release
bosh create-release --name=windows2019fs --version=$TAG --force --tarball "../../releases/windows2019fs-$TAG.tgz"
popd
