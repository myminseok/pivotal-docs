
This documents is for installing ruby 2.4+ on  ubuntu 16 LTS 

http://bosh.io/docs/init-vsphere/
https://github.com/cloudfoundry/bosh-deployment

## as root

```
sudo -i
```


## for bosh create-env dependencies
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


###  to enable RVM environment
RVM is tool for managing multiple ruby environment in OS.
put following to ~/.profile to enable RVM env.

```
vi ~/.profile

...
PATH="$HOME/bin:$HOME/.local/bin:$PATH"

source /etc/profile.d/rvm.sh
```

```
sudo apt-get update && sudo apt-get install ruby-full
```
