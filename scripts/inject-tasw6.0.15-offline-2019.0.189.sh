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
# - imgpkg cli (latest, tested on version 0.43.1) (https://carvel.dev/imgpkg/) for downloading windows2016fs_2019.0.189.tar 
#
# Download resources on workstation
# 1) pas-windows-6.0.15-build.2.pivotal
# 2) imgpkg copy -i cloudfoundry/windows2016fs:2019.0.189 --to-tar ./windows2016fs_2019.0.189.tar 
# NOTE: golang-1.24-windows from pas-windows-6.0.15-build.2.pivotal will be reused. so no need to download from s3.
#
# disk space requirement:
# this script will require disk space:
# - /tmp:  10GB  
# - CURRENT_DIRECTORY: 10 GB 
# 
# How to run:
# 0) clear local cache: WARNING: for complete offline testing, delete bosh local cache for complete offline testing : rm -rf ~/.bosh
# 1) locate files: 
# CURRENT_DIRECTORY/pas-windows-6.0.15-build.2.pivotal
# CURRENT_DIRECTORY/windows2016fs_2019.0.189.tar 
# CURRENT_DIRECTORY/this_script. 
# 3) cli executible: go, zip, git, bosh  note that imgpkg is not required.
# 4) edit this script for source file: tasw_tile='pas-windows-6.0.15-build.2.pivotal'
# 5) edit this script for winrootfs file: winrootfs_tar_file="windows2016fs_2019.0.189.tar"
# 6) run this script. then output will be created under current directory something like "injected-pas-windows-6.0.15-build.2.pivotal" (5GB)


#!/usr/bin/env bash
set -e
set -u
set -x
set -o pipefail

tasw_tile='pas-windows-6.0.15-build.2.pivotal'
winrootfs_tar_file="windows2016fs_2019.0.189.tar"

#======================
SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TMP_TASW="/tmp/tasw_tile"
TMP_WINFS="/tmp/windows2019fs_tar"
TMP_LOCAL_BLOB="/tmp/windowsfs_local_blob"


rm -rf $TMP_TASW
unzip "$tasw_tile" -d $TMP_TASW


# repackage all the image layers from pre-downloaded resources under $TMP_LOCAL_BLOB
## fetch target windowsfs version
## manually modifying version will break "bosh create" step(unable to find required files)
## TAG=2019.0.167
pushd $TMP_TASW/embed/windowsfs-release
if [ `uname` == "Linux" ]; then
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -oP '\d*\.\d*\.\d*')"
else
  TAG="$(cat ./config/blobs.yml | grep 'windows2019fs/windows2016fs-' |  grep -o '\d*\.\d*\.\d*')"
fi
popd

if ! [[ "$winrootfs_tar_file" =~ "$TAG"  ]]; then
 echo "the $winrootfs_tar_file doesn't match with version $TAG embeded in  $tasw_tile tile"
 exit 1;
fi

rm -rf $TMP_WINFS
mkdir -p $TMP_WINFS/blobs/sha256
tar xvf $winrootfs_tar_file -C $TMP_WINFS/blobs/sha256

FILES=$(ls -al $TMP_WINFS/blobs/sha256/*.tar.gz| awk '{print $9}')
for i in $FILES; do 
  NEW_NAME=$(echo $i| sed 's/sha256-//g' | sed 's/.tar.gz//g')
  mv $i $NEW_NAME
done

## creates metadata file that is supposed to be created by hydrator
## following contents are obtained from execution output of the winfs-injector-0.26.0 

## 1) pas-windows-6.0.5-build.2.pivotal-injected/releases/windows2019fs-2.67.0.tgz/windows2016fs-2019.0.167.tgz/oci-layout
cat << EOF > $TMP_WINFS/oci-layout
{"imageLayoutVersion":"1.1.0"}
EOF

## 2) pas-windows-6.0.15-build.2.pivotal-injected/releases/windows2019fs-2.82.0.tgz/windows2016fs-2019.0.189.tgz/index.json that points to the above manifest
echo '{"schemaVersion":2,"manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:ae6a7a015ddb1950811cefcb39c9c7d7e29bb82f88459867ca1c9744b10a5933","size":6826,"platform":{"architecture":"amd64","os":"windows"}}]}' \
> $TMP_WINFS/index.json

## 3) write manifest that points to diffIds config file above
## pas-windows-6.0.15-build.2.pivotal-injected/releases/windows2019fs-2.82.0.tgz/windows2016fs-2019.0.189.tgz/blobs/sha256/ae6a7a015ddb1950811cefcb39c9c7d7e29bb82f88459867ca1c9744b10a5933
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## the same info can be obtained from manifest.json that is packaged in windowsfs/windows2016fs_2019.0.189.tar/manifest.json  after "imgpkg copy -i cloudfoundry/windows2016fs:2019.0.189 --to-tar ./windows2016fs_2019.0.189.tar"
file_name="ae6a7a015ddb1950811cefcb39c9c7d7e29bb82f88459867ca1c9744b10a5933"
echo '{"schemaVersion":2,"config":{"mediaType":"application/vnd.oci.image.config.v1+json","digest":"sha256:cdcba6b9cdda427c65a9125cda173a7ad913c2b96f1b556781c1c09f08b235f4","size":3199},"layers":[{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:803f4a9590cb9c635813cbd0ee89190f92d5fe4c7589711cf468879e42ce02ba","size":1720268357},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:f8d949f82a48e7c53af792160596b10005419fbc7ecfed6bc45bbeee3a5a2f07","size":442457492},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:1bc2b24231ec14eeb05f029843cf3d383ae8cc71ec7108c3493ef30c5cb38379","size":1415},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:464d9399e3b09cbc4443edcc750fe0621e5f314b530fde2bc569688c5cd79fa1","size":1291},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:3ae6662c9c2d0cd892b510de7e97187d0876ebd84d560670ae3d3943de25950e","size":1290},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:d12c77d53ff645e23ae0b852478368782b40b33a5d44ede6654cb1ba59d86447","size":292025},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:92fb8fa4b12072465fded593335f84e80bfe9b5632109ab0917e58f6e195553f","size":248966},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:bc9065ec09328c0e7359c94582626d69a52652edf3a16fe085e7596fcf8b8dca","size":28885596},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:87c1772a52850b441c5866a01af2b62837f6d6d0a7d79fe4ed7bcdd9834f1b2d","size":69823654},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:12e07badab204b6a8a408a318d84b76a8ddc62204f6603e0dd2737b38771d093","size":174721546},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:8190bbb2e470db07195a24aec5082dad4ce9422b22d6c0597518a3349a071cb8","size":310860},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:7ab010e5b8576ec9924463f42390a390763766f3692a4a0a5830b540d109c3d4","size":5504769},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:c73d94148f939dd168e99d9df996a5f8dabe2a73127530bd88893ece2c38e6da","size":17505954},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:e0a22d5d84c1750fa846dfa22179d2d4d8b0675ed878d1ac7ba7f0979fd855cd","size":8968505},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:d91bfa8639add590d861aecd21c16ac6104af2375c1f08e946870ee24e8a4307","size":16141361},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:f660ce8776da7f5f2c36045254cc1a56af756e60e9a5937dd4f0232b21c11866","size":374773},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:1608da823d98a090f2f95e5103acbb9139809cf41252e6292ac3293caacfdfe7","size":10252373},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b5b3f4c5180480d1679ce6e6f3d2fd613a5b6d495cc5240418f0337b2154d9c9","size":18192001},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:c1c2a7ff3bd682db8f18a93284d79396ace5e5273e1599fb22bac71d50f8b6af","size":380349},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:86180e51792f753d00af19b489a6ea186c73234bf93f918e659f8c93c4c98b45","size":13583199},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:87d389c6203310340301ebb42be4fe46393c657f12a6d27142a40aff99f5a58e","size":13384458},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:dadb2198a884ae365cba545d76b47288041ed669a8b4d22b9aeafc6b8423e805","size":406263},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:c8dcbe202f7a4f589bcd0c8341f13821de93ff7678e2cd3e1f0cd3096baffd16","size":25011581},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:efa9222b2b1d238c75d5baf798b9d753c2a429c03603de9d569a70ee28488ce3","size":21138796},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b2c891edb0e5b34d40303738df1db446b384394b9a1e75c281b25cd9e301aba1","size":448121},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:032fc494f407bc924cf95ec20f3f4dec6d19032a88a221e39846bf2aaf0b1112","size":1298},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:1f43f40a6e1b63250c6c318f7d253a109805d087cd53b925323745893ca28226","size":1295},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:42907a259ee6c390dbe5e64d0e54aef8a6196185007b97838855240517f4ffc0","size":321579943},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b6c44ae90937cb3dbf38ad75dc654fc30c024b4fc0f72444c3ea68171fb89ef9","size":6164228},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:f6add6642f179c5501f13ac22bbb801bacbaa440f89ba2d8d79c19803c84c615","size":93317883},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:38bf0743bf47d118ccfc94329d2a15d727fb5973e88c33b088f60ec48ab6a71a","size":284842922},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b6a6b4208f909b83accfb9bdd93c6fccc5fb0aab88ac21e9829973c524ffc903","size":563482},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:cf703f1a2e8edc93f603f29430d4df365488aa0a0e9e15eb57b0bc9b3a4d921b","size":6278765},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:7deb1cc36ca99585f82d9cfde40bf473cbc93b9da2ec7e83ef39a56952760dce","size":188243840},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:06afe48830e888163dc73b9b9ef7e80d3661271376753397e640c0599450311e","size":173143694},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:5f2de34e688c8ca888d3272b813c0c3891697de81d3f0e94ca72e701b224bddd","size":21331437},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:3c262fd231f82361932312fa43cc823b25c0aa8d52a655d3299a273efe683c82","size":710286},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:86458e86729aa77c6da60fa4c23c3141d3ebe8741fdf5ab9f50df0150b56ee30","size":711154},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:b75d40da0014a5d759389801395e829e59b07f4e0d922bba7d6979a73f070903","size":1245546},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:195a533d0b330882f18810b8d4e836940020d3a70fee926aa2944cc035813ce7","size":714449},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:19b893f5211170108cfb6e8a0dc8815bd6712b2482a5f5040fe1db6b1e443881","size":731402},{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:93ffee0ef8bc4565400942535b34ad83f5aec3985f28d9f8d62ece470ccbb68b","size":742126}]}' \
> $TMP_WINFS/blobs/sha256/$file_name
# remove new line at the end of file to keep sha256sum.
truncate -s -1 $TMP_WINFS/blobs/sha256/$file_name
actual_hash=$(sha256sum $TMP_WINFS/blobs/sha256/$file_name | awk '{print $1}')
if [ "x$actual_hash" != "x$file_name" ]; then
    echo "sha256sum hash of file $TMP_WINFS/blobs/sha256/$file_name doesnot match" 
    exit 1
fi

## 4) write diffIds config file 
## pas-windows-6.0.15-build.2.pivotal-injected/releases/windows2019fs-2.82.0.tgz/windows2016fs-2019.0.189.tgz/blobs/sha256/cdcba6b9cdda427c65a9125cda173a7ad913c2b96f1b556781c1c09f08b235f4
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/downloader/downloader.go#L66
## https://github.com/cloudfoundry/hydrator/blob/27f4e1335b72ffb08629419371e6fb90801f9db0/oci-directory/write.go#L19
## the same info can be obtained from manifest.json that is packaged in windowsfs/windows2016fs_2019.0.167.tar  after "imgpkg copy -i cloudfoundry/windows2016fs:2019.0.167 --to-tar windows2016fs_2019.0.167.tar"
file_name="cdcba6b9cdda427c65a9125cda173a7ad913c2b96f1b556781c1c09f08b235f4"
echo '{"architecture":"amd64","os":"windows","config":{},"rootfs":{"type":"layers","diff_ids":["sha256:189e610b66c27c43088a7a197223619ece76d2d755bcf7731cf0b22fc4adf2c4","sha256:9f228d44ac81007bcd01335d9485df668cea16182104f1edf4d3af023f242cdf","sha256:2f452347cbfe82c4faaabcfff0912c6e855b9d83ee9eca238124148da4a70c97","sha256:ae3556d59fff3caa37d8001ef4e26c91857ed5d386f2738585553c78041f737c","sha256:c34a79e3a7dfb9dabb73764b4fbab1c724000efd2f58297200115469c41719e3","sha256:2dacf5a0473ad29519f1cc294da7dfced83be1180e23f3bc2f286debd617b46f","sha256:30969e4b35c20a0e0e1bfcc1375af93f0e3203e51ad7c76ec28bbebf004da052","sha256:ef913dcf34bb3f0eacfb9e73dc0592d5d1a15818d16f392f5ec0d22e34878160","sha256:fb4c39585db60df8d6fd1495b3720fc582295d74c152611ff079ef16b572420d","sha256:169f06beb89984e3e01e47dbda1e726c603f511e63ad4417fc6a7c38b2cee63a","sha256:de9492779478866e9b714eaac1932cdc7f1cd4e635d4d85495486bd38a38716c","sha256:216cb86a7424c3b4b386dd4e17d18e5aa2a93615e44c7c656465858ae816c5da","sha256:db0a3e9407991d2ddba408035360241be1daf768819ae11937750931bd0cc836","sha256:7fdced1271bf8dc5aa96a645bd54b558e160d4530007e8b5194c1812e1cf6b93","sha256:1dc8d455a7c9589647b410254cb7fec5675decf59d72748fe8517194d978dafc","sha256:767687b0c1d0ffebe6eb0eb221c201d168fff814ea85b3502d449ec8934593d0","sha256:39ae62cfdeaf2839165c26242556b3a5e15f312439d67aab5b0b0793dcca8794","sha256:a9ddfacb3c0e399e4825b0771fe19d02ce5d648d161dfbab37518e29c6964392","sha256:aa57e357b3a5c57bb3dbf121ea10bed6753a03f2b7c5b46e4eebfcff75d788cf","sha256:31af90663041a325cb79ac0626ea8e06e85a369ca66805703cd1ab1cf1175d83","sha256:d75ef810553d142d6853af2ed3021eb11ee10ad8aca86a7c14af44903fb7ea1d","sha256:1a92d1cbc09c7c3f8f7cf85b221b80c324b3e1992df5b06a791394171edcf72b","sha256:6b3e237e4e1857730d28780949c880851b1c47c07a2fb4acdc3569fb52c49860","sha256:3f9da7e1a109b09d9bb8a540d2cf841ffb819a17c9e1a58311164257f2c16a72","sha256:8d3065c0a944b509c9f3aae20693167a8082e861a7063fd96e5b4cc956783b87","sha256:d1f253211e69515cfe2554059232705b6cb4ed5790b1dd2c2aa0e425e1b8c4d1","sha256:f7ed3e252b9f7b576de4ad3b0b393977d937f4ad7cfe67d8a9fbe16fe965cf4a","sha256:2e68586bb87674ad967ca9baf6f0ea85f3b9e9156aa559390acc21e4371470a7","sha256:37ce56a1ada4105c092e773d50c20e21dc125c4d1bfd95964ad79e79ddd341d8","sha256:4fbba49003ae407ca9e444f065c5ba68db7b90576f189a0fd748e90a7b9454f9","sha256:14d7a980c2d500a62ad436d3718013be65e13876c0af9807621444d41c343a51","sha256:86b02f84fc1a43f21951c45f48d0706774a78f385b795a22d827341ba995a1e6","sha256:e935bf806913babaf70a5d553ddf01d7cafd39ea02c4fddfd4730e8fb6a67530","sha256:1ae5d2414b9ff73f7913a0e5f7937886070c59fd5979f09bc6e6579f2bcd38ba","sha256:bd3107ecadccf9bdf9aceb912ea69ee7054bc1095cbf9223d21f00e4b4d59168","sha256:2292eeab82690bf1af849b7043e4827646354f947de798972cca31e4b466e695","sha256:dcef9261d6f4b16c4b36556cd0d10fb6f140af0e4feb4b9b3368442d86768a93","sha256:1311be5b7e02c2e01028e9987d747f35d05c0147fe89689858efc23b5520a81c","sha256:e6004fda7aafb3859936448230f2864298a66e41629fa3800cc478b2be7b546f","sha256:2721fb8c9b7f04ec31646560e1475481e3d851d9e2c6e1c2d847cc63fa0adea7","sha256:0b63c3ba20994d0feb3882a847934a206687fe9b56cda4950729419661468d9b","sha256:a058054b2a02f45c190274bf8b4e3f86dbb6fd8e8a17ebee2f63568c5f69b906"]}}' \
> $TMP_WINFS/blobs/sha256/$file_name
# remove new line at the end of file to keep sha256sum.
truncate -s -1 $TMP_WINFS/blobs/sha256/$file_name
actual_hash=$(sha256sum $TMP_WINFS/blobs/sha256/$file_name | awk '{print $1}')
if [ "x$actual_hash" != "x$file_name" ]; then
    echo "sha256sum hash of file $TMP_WINFS/blobs/sha256/$file_name doesnot match" 
    exit 1
fi


# tar release and place under bosh release
pushd $TMP_WINFS
tar zcvf /tmp/windows2016fs-$TAG.tgz *
popd

pushd $TMP_TASW/embed/windowsfs-release
mkdir -p ./blobs/windows2019fs
mv /tmp/windows2016fs-$TAG.tgz ./blobs/windows2019fs
rm -rf $TMP_WINFS
popd


## fetch golang-1.24-windows.tgz from pas-windows-6.0.15-build.2.pivotal

## golang-windows blob id
## this golang-windows blob id should match with ppas-windows-6.0.15-build.2/embed/windowsfs-release/.final_builds/packages/golang-1.24-windows/index.yml
## by refrencing pas-windows-6.0.15-build.2/embed/windowsfs-release/packages/golang-1.24-windows/spec.lock
## otherwise it will fail on bosh create-release below.
golang_windows_blobstore_id="20a86101-e2f1-4382-4c8a-4bc70e590ac8" 

## fetch golang-windows release.
pushd $TMP_TASW/releases/
winc_tgzs=($(find . -name "winc*.tgz"))
winc_tgz=${winc_tgzs[0]}
mkdir -p $TMP_LOCAL_BLOB/tmp_golang
tar xvf ./$winc_tgz -C $TMP_LOCAL_BLOB/tmp_golang
golang_tgzs=($(find $TMP_LOCAL_BLOB/tmp_golang -name "golang-*-windows.tgz"))
golang_tgz=${golang_tgzs[0]}
cp $golang_tgz $TMP_LOCAL_BLOB/$golang_windows_blobstore_id
rm -rf $TMP_LOCAL_BLOB/tmp_golang
popd 



# Update the bosh blobstore to be local and not use S3 (https://s3.amazonaws.com/windows2019fs-release/1d3bd634-0e80-4a91-7970-5eee8b0d6ce2)
cat << EOF > $TMP_TASW/embed/windowsfs-release/config/final.yml
---
name: windows2019fs
blobstore:
  provider: local
  options:
    blobstore_path: $TMP_LOCAL_BLOB
EOF

pushd $TMP_TASW/embed/windowsfs-release
# Create a dev release
bosh create-release --name=windows2019fs --version=$TAG --force --tarball "../../releases/windows2019fs-$TAG.tgz"
popd

# Remove our working content so we don't bloat the tile
pushd $TMP_TASW
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
zip -r "$SCRIPTDIR/injected-$tasw_tile" .
popd

# Cleanup
rm -rf $TMP_TASW
rm /tmp/metadata-ops.yml
