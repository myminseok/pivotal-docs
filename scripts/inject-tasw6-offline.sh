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

# Crack the tile open into the tasw directory
#tasw_tiles=(./pas-windows-*.pivotal)
tasw_tiles='pas-windows-6.0.5-build.2.pivotal'
tasw_tile="${tasw_tiles=[0]}"
rm -rf ./tasw
unzip "$tasw_tile" -d ./tasw

# repackage all the image layers from pre-downloaded resources under /tmp/windowsfs/
## fetch target windowsfs version
## manually modifying version will break "bosh create" step(unable to find required files)
## TAG=2019.0.167
pushd ./tasw/embed/windowsfs-release
if [ `uname` == "Linux" ]; then
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -oP '\d*\.\d*\.\d*')"
else
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -o '\d*\.\d*\.\d*')"
fi
popd

rm -rf /tmp/windows2019fs_tar
mkdir -p /tmp/windows2019fs_tar/blobs/sha256
tar xvf /tmp/windowsfs/windows2016fs_2019.0.167.tar -C /tmp/windows2019fs_tar/blobs/sha256

FILES=$(ls -al /tmp/windows2019fs_tar/blobs/sha256/*.tar.gz| awk '{print $9}')
for i in $FILES; do 
  NEW_NAME=$(echo $i| sed 's/sha256-//g' | sed 's/.tar.gz//g')
  mv $i $NEW_NAME
done

## creates metadata file that is supposed to be created by hydrator
## following contents are obtained from execution output of the winfs-injector-0.26.0 

## 1) pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.167.tgz/oci-layout
cat << EOF > /tmp/windows2019fs_tar/oci-layout
{"imageLayoutVersion":"1.1.0"}
EOF

## 2) pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.167.tgz/index.json that points to the above manifest
echo '{"schemaVersion":2,"manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:595e544a7d518e7da8dd45eed60e7192cf67bbb8d7c668f5bcfdb74d9413432a","size":5415,"platform":{"architecture":"amd64","os":"windows"}}]}' \
> /tmp/windows2019fs_tar/index.json

## 3) write manifest that points to diffIds config file above
## pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.167.tgz/blobs/sha256/595e544a7d518e7da8dd45eed60e7192cf67bbb8d7c668f5bcfdb74d9413432a
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## the same info can be obtained from manifest.json that is packaged in windowsfs/windows2016fs_2019.0.167.tar/manifest.json  after "imgpkg copy -i cloudfoundry/windows2016fs:2019.0.167 --to-tar windows2016fs_2019.0.167.tar"
file_name="595e544a7d518e7da8dd45eed60e7192cf67bbb8d7c668f5bcfdb74d9413432a"
echo '{"schemaVersion":2,"config":{"mediaType":"application/vnd.oci.image.config.v1+json","digest":"sha256:a04dc9c99773acb6521f3412054001b0f190711453944e0f45c82c6825f58a62","size":2533},"layers":[{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:c9226d61d3bdbf9f09821b32f5878623b8daaa5fb4f875cb63c199f87a26d57e","size":1650620357},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:56a5fd77f8cb6921d3e283f98213bf8c163d3502a75b4a8e4a809a15654f7d1a","size":570060810},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:5b79aa06f75d48d3e0f51006ca1b4cbb4cd3b3b2252cd44a746d8926d06e24e7","size":6743740},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:4a4c3b770ae3afb9b87ab24a45f87d4e9cce554cab55e175459a1c46d3bd96c9","size":314005},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:267a167f835f343c9a4c92a3221f827b7a3e5e54d6894d24a642f85c154e86c3","size":28539621},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:09f1456d99ef78d908c36e3f15e0497084ff4d21b9f9306e3af38f7669bec397","size":67646756},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:36d2a1a4a67432fa6272635699fdfe7b0143cb5dae0a0b8ac8654fa066b58759","size":169318898},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:cc70960bda1bb81e99720563c7191445e787cd73a4e6935651d4f65eec382fab","size":336193},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:d932d72527a5fcae91a4c8027a7b5963869507b780cd4fa485c47a494f35bcf1","size":5504726},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:74caac324cc73406306cedf8fa36c5b15bd8621ad8b45f265f1418f7d48f39fd","size":17484645},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:3493c281203d549b8cfc3a960179d15218efa376180f0b6c0d28314de3275f7d","size":8968487},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:491cfcb5c48917d84f9ca7654a48ea79302b90b9ec4216b008116024fc00a656","size":16144752},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:cd6b92dfe9f3a693d209dd53609477c5e4153a548faaea3b37f6c7bfb8e4ab39","size":364573},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b313b98a2d88520c2a182ab65f33d009584b14563433d14b48b94af62b668312","size":10252420},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:2a345147a08fcec473530abaf62bf40b9d947c3af74a16d24d9170258251ea01","size":18195107},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:d4554051afa4d76c362244ca68e30307d26cf56ec4d3787f65f65c0b616a24a7","size":391346},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:42f54c7c4bb2f1d13fe98441467391759adf12073e27c0aaec19751969640745","size":13583279},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:462e32ada7d07c53f5e2d201a07a2b0e42e19a456a9d5b300cb5f2a6be0b227b","size":13389020},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:7bbff9483acea8452e874f693242197ebbf54487db9eb57988521712daa597a0","size":415600},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:9fc0642bf908c78ac26fe65c990a64f29ce1e09bf8275357421173fcb1d16305","size":25011659},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:1ef87888dbccba07a276802f783f322c6d9b4df6777633bf095f21c455efd18b","size":21154437},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:76b70b70c0e62e0f7cdcf5b64cb61e22022a1c7f2cd056efb2f321903ed1c53b","size":441933},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:efc06b4dcfaa1bbf5c1feecee9a327a28328d1868311a5d97fd240c0c5184ff9","size":117302566},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:e5a3fe9f182516bb054be15300a87f39292ade7aeca5e0236426c663a545fe6d","size":316185396},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:26a37cc98b5bdf683485bed1cf855871d9ec560ebb7d8995922aa52acd0658be","size":523796},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:44660cecfbbb13862df25660ac2f6e0ff2c8c5daa147d8624fa89b459c539233","size":7148356},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:56ac04e25ed2e7d4698c9a70ab2171652b3eec280a45f8158d2247185f0535a4","size":18961150},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:d7b1eea60e5a1da44f930f80cfe1348f23b820b853ffd2f68e9d8fc986af618a","size":594642},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:5dd6c92c7d84ff58b545ee55a5030612b983b4f3c5fcc48771e3aa4b82dcf9a3","size":591021},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:9e7c66578a5e497973e372938bc299a8bec099e1bc45ddff05fba417ce43ae77","size":1141302},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:17cfb6b02e80ab239b9096be15ec176001455444b3631d082ff3ca14195ff5a0","size":605831},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:101843ed5fa4ef6e5807afffc662f2d6b772edb88940b0b56cd60e19399ac116","size":588370},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:694b69b21d8c96a84e732e5eecaa1880b388dd0821858da411d11a0164b30350","size":622418}]}' \
> /tmp/windows2019fs_tar/blobs/sha256/$file_name
# remove new line at the end of file to keep sha256sum.
truncate -s -1 /tmp/windows2019fs_tar/blobs/sha256/$file_name
actual_hash=$(sha256sum /tmp/windows2019fs_tar/blobs/sha256/$file_name | awk '{print $1}')
if [ "x$actual_hash" != "x$file_name" ]; then
    echo "sha256sum hash of file /tmp/windows2019fs_tar/blobs/sha256/$file_name doesnot match" 
    exit 1
fi

## 4) write diffIds config file 
## pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.167.tgz/blobs/sha256/a04dc9c99773acb6521f3412054001b0f190711453944e0f45c82c6825f58a62
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## the same info can be obtained from manifest.json that is packaged in windowsfs/windows2016fs_2019.0.167.tar  after "imgpkg copy -i cloudfoundry/windows2016fs:2019.0.167 --to-tar windows2016fs_2019.0.167.tar"
file_name="a04dc9c99773acb6521f3412054001b0f190711453944e0f45c82c6825f58a62"
echo '{"architecture":"amd64","os":"windows","config":{},"rootfs":{"type":"layers","diff_ids":["sha256:da2d874340bd0ca5f710fcb2bb9abc7423e71287e9f2b87694767375272e797d","sha256:1b5c0765457600a3ad2e242d7bd00b7ad4c759817dc0183122ee6eebc805e68a","sha256:ff2737e26e03ad81501f137ad72f46f29d0e302578c32d2bd9fb23a3e914415f","sha256:fbd637eb8ef780ab46bc596bbd8ac09ea1fe1fbf1f7a52e185479c4b3569c341","sha256:8057753329800099e23c3a2f0f15c77d87db6a683873266f0022a95ad1ee2e5e","sha256:3b4138cefd69112253e815bb676ecd6d567f9f9a208cc72507f16fdaf069033d","sha256:e17350952f5dcefacae6fd8a38bcbb7f5ef89472aefb87e7df838ebd87e2c020","sha256:26fa564b606c5242fa736ac486f93ebbef9d0da561c2da2953e1e16eb0d0ae7c","sha256:2dea7f2b20de85db9f3b62435962fdb5deb6acbe27a3d7b2119d5e8387702004","sha256:6894b201435db601d7afbbdc627c52e5e464c4ea6e921197d8a2044e837f78e7","sha256:914655ebba8622b7613eb8223f4f0aac080b66f03a240213622ee15bc3105bc5","sha256:cbc3194beacbc047de9fee331d67d3374cad7addbca833d0cea11f0524a75a29","sha256:0549706e5a9759cfffad4fc72423b25b77e90c5d8e3a761d518791c52488f1ef","sha256:4c45caa249a214320f8670acffe17312477548b8b105dafd85ed215552b4ad65","sha256:0902d01a39e916807bc7c66482f7b264fb8f5ac1a4eb32e803fa1e79db35a80b","sha256:0bf2df9bab6949918cabd4e00bbfc5e6ef6876f70faf6723d26ef0b9c217a43f","sha256:7d354377fcd28a7d697627ae46f0bfa3ab1906d90e98ef337c7ceeb8c4ed5d23","sha256:73e98fab70376c0f5a3f421f708b863dd2e13f5317cb98b659249ad13654f1db","sha256:e411a9f8df6bb9e8fd866420e5b9e1e8a0bf47db184eb9f4466c647f13f748c3","sha256:33bd8c6c5a02f06f6c23e4699f2bf098042916b995be005cf1885e084c6282b2","sha256:49774fcfb3d0ef5425ed521f696a60f140adb9c92e6c50af122766c1b8e781b1","sha256:105f0ba3093b57d3ea65a28d7e0e90e73c8c333ebdd0fa60342db84159fcee41","sha256:49d3bc0a65644427edcfd8cac68fb3bad24c78042fb0b8defe82e4e06cf9f6ed","sha256:56f0107e5db63271bd69a5e735f714a59b494a84665cd9d59da926be64860b81","sha256:fc9aa6238c5b7ee7651ab39dbc6773977d4ab73e69ae6fd84b465cc9aef3252e","sha256:f1f0b5fd3bde3778a81b9aabc4998668b317653894ce7fd2d233f0bbe977f083","sha256:7b108336c7ba6a81f47f1b317e9c22bb09a164facddc14e7f1d89514e75c0f6f","sha256:41f109525a5bf7d6a148c84f9753e1079de69e7a24aa576fc42eedb84766bbee","sha256:9d883b052937a51ebefb20cc2fef8b2280348f197528001a0b4b9ca1e2ca37d9","sha256:ca72e81366596e9056d5d9c2a47e6cbcee2311fcda8d7643d025fa2f28e130bd","sha256:ceace9c0de0549205749883566bf19ab8ba0455437728b992c4fcab276fb4010","sha256:859ae70e07626fe7af2316eb83c3f1756fcaa303a24ecdf2ab0ea972db2c2f64","sha256:fc34404edfd1727ac8657f79538ac644c8aa65b971ddecf2d199ddbb5f535184"]}}' \
> /tmp/windows2019fs_tar/blobs/sha256/$file_name
# remove new line at the end of file to keep sha256sum.
truncate -s -1 /tmp/windows2019fs_tar/blobs/sha256/$file_name
actual_hash=$(sha256sum /tmp/windows2019fs_tar/blobs/sha256/$file_name | awk '{print $1}')
if [ "x$actual_hash" != "x$file_name" ]; then
    echo "sha256sum hash of file /tmp/windows2019fs_tar/blobs/sha256/$file_name doesnot match" 
    exit 1
fi


# tar release and place under bosh release
pushd /tmp/windows2019fs_tar
tar zcvf /tmp/windows2016fs-$TAG.tgz *
popd

pushd ./tasw/embed/windowsfs-release
mkdir -p ./blobs/windows2019fs
mv /tmp/windows2016fs-$TAG.tgz ./blobs/windows2019fs
rm -rf /tmp/windows2019fs_tar
popd



## fetch golang-1.22-windows.tgz from pas-windows-6.0.5-build.2.pivotal
pushd ./tasw/releases/
diego_tgzs=$(find . -name "diego*.tgz")
diego_tgz=${diego_tgzs=[0]}
mkdir -p /tmp/windowsfs-golang
tar xvf ./$diego_tgz -C /tmp/windowsfs-golang
golang_tgzs=$(find /tmp/windowsfs-golang -name "golang-*-windows.tgz")
golang_tgz=${golang_tgzs=[0]}
cp $golang_tgz /tmp/windowsfs/a8759efa-bd04-41c9-778f-7fbc98b3fe82
rm -rf /tmp/windowsfs-golang
popd 


pushd ./tasw/embed/windowsfs-release
# modify meta to reuse golang-1.22-windows from pas-windows-6.0.5-build.2.pivotal instead of download from s3.
# and it should also be matched with ./.final_builds/packages/golang-1.22-windows/index.yml
cat << EOF > ./packages/golang-1.22-windows/spec.lock
name: golang-1.22-windows
fingerprint: d58174aba07bdc1913cba21648c64b8716d80b6be58bba2b53a37599aa806a0c
EOF

mkdir -p /tmp/windowsfs
# Update the bosh blobstore to be local and not use S3 (https://s3.amazonaws.com/windows2019fs-release/1d3bd634-0e80-4a91-7970-5eee8b0d6ce2)
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
zip -r "../injected-$tasw_tile" .
popd

# Cleanup
rm -rf ./tasw
rm /tmp/metadata-ops.yml
