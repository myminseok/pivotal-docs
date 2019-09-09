
## ubuntu 16.04 VM(internet accessible)
```
apt update
mkdir openjdk8-ubuntu 
cd openjdk8-ubuntu

apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \ --no-conflicts --no-breaks --no-replaces --no-enhances \ --no-pre-depends openjdk-8-jdk | grep "^\w")

cd ..
tar zcf openjdk8-ubuntu.tar.gz openjdk8-ubuntu
```

### ubuntu VM( air-gapped) 16.04: comment out all repo pointing internet.
```
vi /etc/apt/source.list
```

### ubuntu VM( air-gapped) 16.04

```
tar xf openjdk8-ubuntu.tar.gz
cd openjdk8-ubuntu

rm openjdk-9*
dkpg -i *.deb


apt-get install -f


java -version

export JAVA_HOME=/usr/lib/jvm/default-java


```

