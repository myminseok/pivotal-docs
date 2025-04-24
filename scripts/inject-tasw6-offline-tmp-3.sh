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


# Remove our working content so we don't bloat the tile
pushd /tmp/tasw
# rm -rf /tmp/taswembed
## just for backup just in case of re-running this script.
rm -rf /tmp/embed
mv /tmp/tasw/embed /tmp

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
zip -r ~/"injected-$tasw_tile" .
popd
