# README
#
# This script will inject windows2016fs:2019.0.165 to the windows tile instead of default windows2016fs:2019.0.167. 
# see script contents with TAG="2019.0.165" and it is not updatable as it depends lots of metadatas
#
# This is an alternative script to 'winfs-injector-0.26.0' for air-gapped environment. 
# 'winfs-injector' uses `hydrator` internally to download all windowsfs layers and dependencies from internet and packages to pivotal tile. 
# this script does not require internet outbound connection as it doesnot use hydrate but does the same with script with pre-downloaded resources
# should support as-windows-6.0.X-build.2.pivotal(tested for pas-windows-6.0.5-build.2.pivotal, pas-windows-6.0.6-build.2.pivotal only)
# tested on Linux VM or Mac OS.
#
# Prerequisites
#
# Install tools on workstation 
# - install go (latest)
# - install zip (latest)
# - bosh cli (latest, tested on version 7.8.2) (https://github.com/cloudfoundry/bosh-cli/releases)
# - imgpkg cli (latest, tested on version 0.43.1) (https://carvel.dev/imgpkg/)
#
# Download resources on workstation
# 1) pas-windows-6.0.x-build.2.pivotal
# 2) (can reuse the package used for pas-windows-4.0.24-build.2.pivotal) imgpkg copy -i cloudfoundry/windows2016fs:2019.0.165 --to-tar /tmp/windowsfs/windows2016fs:2019.0.165.tar 
# NOTE: golang-1.22-windows from pas-windows-6.0.5-build.2.pivotal will be reused. so no need to download from s3.
#
# How to Run
# WARNING: for complete offline testing, delete bosh local cache for complete offline testing : rm -rf ~/.bosh
# 1) locate files: 
# CURRENT_DIRECTORY/pas-windows-6.0.5-build.2.pivotal
# CURRENT_DIRECTORY/inject-tasw6-offline.sh 
# /tmp/windowsfs/windows2016fs:2019.0.167.tar
# 2) update this script for source file version: tasw_tiles='pas-windows-6.0.5-build.2.pivotal'
# 3) run this script. then output will be created under current directory something line "injected-2019.0.165-pas-windows-6.0.5-build.2.pivotal"


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
## TAG=2019.0.165
pushd ./tasw/embed/windowsfs-release
if [ `uname` == "Linux" ]; then
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -oP '\d*\.\d*\.\d*')"
else
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -o '\d*\.\d*\.\d*')"
fi
TAG="2019.0.165"
popd

rm -rf /tmp/windows2019fs_tar
mkdir -p /tmp/windows2019fs_tar/blobs/sha256
tar xvf /tmp/windowsfs/windows2016fs:2019.0.165.tar -C /tmp/windows2019fs_tar/blobs/sha256

FILES=$(ls -al /tmp/windows2019fs_tar/blobs/sha256/*.tar.gz| awk '{print $9}')
for i in $FILES; do 
  NEW_NAME=$(echo $i| sed 's/sha256-//g' | sed 's/.tar.gz//g')
  mv $i $NEW_NAME
done

## creates metadata file that is supposed to be created by hydrator
## following contents are obtained from execution output of the winfs-injector-0.26.0 

## 1) pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.165.tgz/oci-layout
cat << EOF > /tmp/windows2019fs_tar/oci-layout
{"imageLayoutVersion":"1.1.0"}
EOF

## 2) pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.165.tgz/index.json that points to the above manifest
echo '{"schemaVersion":2,"manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:817f551aeb16ca932aa3ee7b09e8e818042c0650c87711faae17e4900b5e6f5b","size":5416,"platform":{"architecture":"amd64","os":"windows"}}]}' \
> /tmp/windows2019fs_tar/index.json

## 3) write manifest that points to diffIds config file above
## pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.165.tgz/blobs/sha256/595e544a7d518e7da8dd45eed60e7192cf67bbb8d7c668f5bcfdb74d9413432a
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## the same info can be obtained from manifest.json that is packaged in windowsfs/windows2016fs:2019.0.165.tar/manifest.json  after "imgpkg copy -i cloudfoundry/windows2016fs:2019.0.165 --to-tar windows2016fs:2019.0.165.tar"
file_name="817f551aeb16ca932aa3ee7b09e8e818042c0650c87711faae17e4900b5e6f5b"
echo '{"schemaVersion":2,"config":{"mediaType":"application/vnd.oci.image.config.v1+json","digest":"sha256:ad507d36bfa040e3b82ccf681fffd7872d63f69984bc60af0590f8a162e8d7b9","size":2533},"layers":[{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:c9226d61d3bdbf9f09821b32f5878623b8daaa5fb4f875cb63c199f87a26d57e","size":1650620357},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:e920b78002850882cc637991bf16e3cd3fdd45576cf3e930819c98f6b43518d3","size":513807602},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b70e8df550d36d18c56c44e866e7b63e42bba5407896fed9a796e9ca836a5744","size":9171775},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:1877c661ff31e60169ca44cf8bc9425b6780bf65d0456c01f0bf38fdff613840","size":6206330},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:120b1bf97845c684fa48d5e02dcd38d6c9646e8161197d7d1c124e1c383adf03","size":30631263},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:65dac75e62f53b20d0d5e60d699062fa49989689b62cd79c5134899c2c558613","size":64864693},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:3e0b50230d00404c6f00e8589d1c654495d5a7b0480cf310cd87c00eba52979d","size":166424221},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:722bb59133681d51876736e0c4bee16649d75f01a1aca3db274192fdff57708c","size":332101},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:51de8fbb125e5b8609db1adec38da5eedf1392b0ee78c67d7ef49a00a5b6a7b6","size":5504758},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:7c6c50ee58d5ddba68e58746d23689f50dda23759c28040d9997ee4c65810d1d","size":17467559},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:51eb3fa006df83ebb5d7951be639da454306536e2bc80072f27f5437f2487028","size":8968469},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:14b1f865ef067bee41ea76a26b43010f919858f379a812fb9bec33bc9d473d22","size":16161728},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:8c42b46b26dd0e5b7896db2b3e393ce9dc2313f350d31856bfa6c71e26a3f1b6","size":384576},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:9dbf0582f8a4b52c84611c971862558ed938f2a651ac4ff11254d7d01fd26991","size":10252388},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:687fb2bb08b41ca6fb8529cc2cfa6b57a0f87dc2c78c154f582b503a8e5e5e26","size":18211923},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:da08883b1318822a07e9093ff8bab8723678e9ced7c26999f26c905b799a9f85","size":402174},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:2ca97ec51fe10141fe7625a06cde08be18b32d91078423089de64181b264da2f","size":13583235},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:7c1653ff2f6912ad2e164b7f9d0e94ce7a0fc82414bd961bb0c44e2611d7fd74","size":13397077},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:ed17a6a1adad7b0d8f47f5f2acdb81edf7628cf388b79a733f87b630ada17845","size":429107},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b28cfbf847b4914df451c359ed11881903c45f81acb009f65a458e0d555e1cdc","size":25011585},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:57423135cc70373d12d576bfac864832beefb65bd3316ca066b148e2cc0e7b3b","size":21157654},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:1586efa96b1cced8dc2df2f0464b12441ec0c46e673a13e3b21590b0960bb83c","size":449826},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:1db3eb26b0daff22e532c56362dbf26dd5285bc80b855e0c43a378ca41830bd3","size":117302562},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:7d3ac1eda26ed7a51b5e621eda449d8ec6693fdaac7b80fca19599b51c8d1d3b","size":319009378},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:200f4992c6384b75e38998ad5d34c35c2db26db99480dab76ccb4c72197d5a23","size":544628},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:ccd3dddd03d5c9bc1e63ccea98c59f1f0eeed5000d8dc8615e1e1af7a3acff33","size":6710778},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:e3e45ba8e72034d1113ff074802662160dd0f5f1d24cba7ecb1e03ca1b85f80a","size":21941397},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:2da1d3eb5bea401812440ed508874fcd9d39658d7c581347de0a795171644404","size":606240},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:2b03b757e438ec33e56407e75187a60e9433eaea1afa1a40c88904e59d152549","size":597812},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:fad03c68e8f029ce7aef3ff14904be37c5f75b2eccfe1f7afcc26bfb4c43994c","size":1147959},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b5db996e3aa64699532a73557081f65f2f4bfbcd39af716381f7cbe78d181370","size":614667},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:74390601a05bfd3ab2d9081c04652a0fe567919683882120956cb3315470e516","size":600610},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:022969207dcd6d4d2f23ec17d38a0f8c592bc5a6a5fa0cd6e2ab901cd8ec828b","size":629102}]}' \
> /tmp/windows2019fs_tar/blobs/sha256/$file_name
# remove new line at the end of file to keep sha256sum.
truncate -s -1 /tmp/windows2019fs_tar/blobs/sha256/$file_name
actual_hash=$(sha256sum /tmp/windows2019fs_tar/blobs/sha256/$file_name | awk '{print $1}')
if [ "x$actual_hash" != "x$file_name" ]; then
    echo "sha256sum hash of file /tmp/windows2019fs_tar/blobs/sha256/$file_name doesnot match" 
    exit 1
fi

## 4) write diffIds config file 
## pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.165.tgz/blobs/sha256/a04dc9c99773acb6521f3412054001b0f190711453944e0f45c82c6825f58a62
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## the same info can be obtained from manifest.json that is packaged in windowsfs/windows2016fs:2019.0.165.tar  after "imgpkg copy -i cloudfoundry/windows2016fs:2019.0.165 --to-tar windows2016fs:2019.0.165.tar"
file_name="ad507d36bfa040e3b82ccf681fffd7872d63f69984bc60af0590f8a162e8d7b9"
echo '{"architecture":"amd64","os":"windows","config":{},"rootfs":{"type":"layers","diff_ids":["sha256:da2d874340bd0ca5f710fcb2bb9abc7423e71287e9f2b87694767375272e797d","sha256:b95bb9177b7bd79ff392ee56ab21e602343779e68882b471e0550cdabc7344e0","sha256:4a95345e33d96941b80fd21edbdf4f55ea554c0cebdb5bc29e244d4c34c908da","sha256:30a3a70571db1bf70b294e0d5114fde2ec55d31c7168de4a07bd6a5891e674ad","sha256:646527198e633ede01de49fb3aff8ffc7a5d64e32873ef94acd7bf1b6367aaa3","sha256:1589c2778c0779156c8550913da3aa7ac8c03798ebba34ac9873aba67c78cc33","sha256:77d89d275c20dd4d2b7ade15a255c1ffc30f7150bdd8611094343714d11fb792","sha256:ebcd3235f92fc2fa94d69165b981f8713f8dbe9107bb86df95d3126196f23c90","sha256:41050921fcbbdbdea017f906695389ce3a1f8e71c3c16045cb2be95244158cf6","sha256:4fb26b5e4fb0b99fb9d102798a27b0c83994c44cef1fcafb3f88427744734b8e","sha256:41d0b89f813cc1c4ddf7cdef814f285f1c7ef221db43fb5cbbc4b0c674ba247d","sha256:de8df68e004dde1eb30553b951d1b4ec96c88fe625967d39eb0d4404f6d5d368","sha256:20c13f2a30e1d31a83ee48b6c0c29d1dc1dea33b4473f5853455b863534e320a","sha256:4937fa638bdb455dc5bedf74fe175b4d6a133fe5ba94f37402de36ed178fb31b","sha256:8cb6a180f2e727b46f1862cb8b35940e361cb7fc028c273aebc73bc875621cb6","sha256:41ae89b890220ef4833eca43a0deb03b1772d450007b27b0416bb4607b46daa7","sha256:6c544e964d51f81e25422c87777607050719a2d6143ededada5029fbf519328c","sha256:3a1d48e0e11c143a403574ef08e93c9309064aa45d06a02dd3c5720b695c71bb","sha256:195eb3c3b464e22da696660b8fd89ce680b6714b3d86452af26e44e3d0809325","sha256:2de4e50008fb226e4f4f2f82d391ed65f037c849c5c25b6119e64dc7b1222e5c","sha256:0be5e92ac734ecf9f1e53e0a722f9981fd163625dd0827eefd20aa2c863cffa0","sha256:f3c5f42327da6447607069c53206899416f5f3c61cf8ede03ceae1eacf10bf56","sha256:5dbe541bdf4ef49f9fc29eb8f6119b2839622e7f90713960ad0f70a69982b84e","sha256:e803ac73c8e7b8d08c4775cd5e616c51d6ddf8fcf77b24a45b916304070de3c5","sha256:981fa1b6259c02d8cbf0be40a376eb1cb1a71608ee1cdde27624e21d4a874ccd","sha256:c511f2fb779b846df30ff0a189f1f2c7c86f0e205b058428316201c846988039","sha256:fb95368ab0ae6c6ec472c377695b9f047449caf14e4f6f383b557fa6c9b7f59f","sha256:9bcd8762279cc84a737584310f2464f407ad31eb941ab4c2f0dbff120d04bda0","sha256:7c5aa1f3c9d17c71d3c184a8c40431ec25c82f8867e052a530c1d17806701b5c","sha256:982680967646f4d4829ae4ffc69a86f126854bd3e473dc2867ea87b709b5d6fc","sha256:a22130d6d681abd6116f1f1f09b4387b87a478644e86ea120e4299f41666540d","sha256:a586372999ed2eee353f0bdf880ab400c30366029043b1f4b9b935e272e8c7c4","sha256:6dfa92a7dc2ed855f73e9dbb84f9437dc5a32e75c1c971fc02e22f470fec518d"]}}' \
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
# modify meta to use  windows2016fs-2019.0.165 instead of originally referenced package from pas-windows-6.0.5-build.2.pivotal (windows2016fs-2019.0.167)
cat << EOF > ./config/blobs.yml
windows2019fs/windows2016fs-2019.0.165.tgz:
  size: 3054842036
  sha: sha256:d9477f022eacd1c376e60570e79f60b0a7b7e32c61dbc5198eb6d36f35f74c50
EOF

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
zip -r "../injected-2019.0.165-$tasw_tile" .
popd

# Cleanup
rm -rf ./tasw
rm /tmp/metadata-ops.yml