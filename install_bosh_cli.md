ubuntu기반의 Jumpbox에 bosh cli를 설치하기 위한 가이드입니다.
ruby v2.4 이하일 경우만 실행합니다.

ubuntu 16기반으로 작성되었습니다.

http://bosh.io/docs/init-vsphere/
https://github.com/cloudfoundry/bosh-deployment

## root로 전환

```
sudo -i
```


## 필수 라이브러리 설치

```
apt-get update

apt-get install build-essential zlibc zlib1g-dev ruby ruby-dev \
  openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev \
  sqlite3 zlib1g-dev libcurl4-openssl-dev \
  build-essential make curl \
  -y

```

## ruby설치
bosh는 ruby2.4이상이 필요하기 때문에 RVM을 사용합니다.

```
apt-get remove ruby
command curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install ruby
```

## gem 설치

```
gem install nokogiri -v '1.8.2'
gem install rubygems-update
update_rubygems

## gem update —system
```


## rvm환경 로딩
jumpbox에서 ruby가 설치된 rvm환경을 로딩하는 명령입니다.
이후 bosh명령을 실행할 수 있습니다.
~/.bashrc에 추가하면 편리합니다.

```
source /etc/profile.d/rvm.sh
```
