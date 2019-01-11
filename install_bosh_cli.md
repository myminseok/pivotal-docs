ubuntu기반의 Jumpbox에 bosh cli를 설치하기 위한 가이드입니다.
OS의 ruby v2.4 이하일 경우만 실행합니다.

ubuntu 16 LTS 기반으로 작성되었습니다.

http://bosh.io/docs/init-vsphere/
https://github.com/cloudfoundry/bosh-deployment

## root로 전환

```
sudo -i
```


## 필수 라이브러리 설치 bosh create-env dependencies
https://bosh.io/docs/cli-v2-install/#additional-dependencies
```
apt-get update

apt-get install build-essential zlibc zlib1g-dev ruby ruby-dev \
  openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev \
  sqlite3 zlib1g-dev libcurl4-openssl-dev \
  build-essential make curl \
  -y
  
```


## install ruby v2.4+
bosh cli for create-env command requires ruby v2.4+
we will use RVM for ruby installation.

### install RVM env.
run as root
```
apt-get update
apt-get remove ruby -y

command curl -sSL https://rvm.io/pkuczynski.asc | sudo gpg --import -

curl -L https://get.rvm.io | bash -s stable

source /etc/profile.d/rvm.sh

rvm install ruby

$ ruby -v
ruby 2.6.0p0 (2018-12-25 revision 66547) [x86_64-linux]

```


### install gem

```
gem install nokogiri -v '1.8.2'
gem install rubygems-update
update_rubygems

## gem update —system
```


### loading rvm env
jumpbox에서 ruby가 설치된 rvm환경을 로딩하는 명령입니다.
이후 bosh명령을 실행할 수 있습니다.
~/.profile 추가하면 편리합니다.

```
vi ~/.profile

...
PATH="$HOME/bin:$HOME/.local/bin:$PATH"

source /etc/profile.d/rvm.sh
```

```
sudo apt-get update && sudo apt-get install ruby-full
```
