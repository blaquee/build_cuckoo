#!/bin/bash

#set up the directory to install cuckoo
USER=`whoami`
sudo mkdir /data
sudo chown -R $USER:$USER /data

#update system
sudo apt-get update -y && sudo apt-get upgrade -y

#install dependencies
sudo apt-get install -y vim screen unzip python python-dpkt python-jinja2 python-magic python-pymongo python-gridfs python-libvirt python-bottle python-chardet tcpdump libcap2-bin python-dev build-essential subversion pcregrep libpcre++-dev python-pip ssdeep libfuzzy-dev git automake libtool autoconf libapr1 libapr1-dev libnspr4-dev libnss3-dev libwww-Perl libcrypt-ssleay-perl python-dev python-scapy python-yaml bison libpcre3-dev bison flex libdumbnet-dev autotools-dev libnet1-dev libpcap-dev libyaml-dev libnetfilter-queue-dev libprelude-dev zlib1g-dev libz-dev libcap-ng-dev libmagic-dev python-mysqldb cmake libjansson-dev libcdio-utils mongodb-server python-simplejson p7zip-full libzzip-dev python-geoip python-chardet python-m2crypto python-dnspython 

sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
sudo pip install bottle django pycrypto distorm3 pygal django-ratelimit 


#Set up PEFILE dependency for Yara
wget http://pefile.googlecode.com/files/pefile-1.2.10-139.tar.gz
tar -xzvf pefile-1.2.10-139.tar.gz
cd pefile-1.2.10-139
python setup.py build
sudo python setup.py install
cd ..

#Install Yara
git clone https://github.com/plusvic/yara
cd yara
./bootstrap.sh
./configure --enable-cuckoo --enable-magic
chmod +x build.sh
./build.sh
sudo make install

#install yara python extension
cd yara-python
python setup.py build
sudo python setup.py install
cd ../..


#install pydeep dependency
git clone https://github.com/volatilityfoundation/volatility
cd volatility
python setup.py build
sudo python setup.py install
cd ..


#install pydeep dependency
git clone https://github.com/kbandla/pydeep.git
cd pydeep
python setup.py build
sudo python setup.py install
cd ..


#install cuckoo sandbox
git clone https://github.com/brad-accuvant/cuckoo-modified.git cuckoo
cd cuckoo/utils
./community.py -a -f
cd ../..
sudo mv cuckoo /data/cuckoo


#install virtualbox
echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" |sudo tee -a /etc/apt/sources.list

wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -

sudo apt-get update
sudo apt-get install virtualbox-4.3 -y
sudo usermod -a -G vboxusers $USER

#install the vbox extension pack
version=$(vboxmanage -v)
echo $version
var1=$(echo $version | cut -d 'r' -f 1)
echo $var1
var2=$(echo $version | cut -d 'r' -f 2)
echo $var2
file="Oracle_VM_VirtualBox_Extension_Pack-$var1-$var2.vbox-extpack"
echo $file
wget http://download.virtualbox.org/virtualbox/$var1/$file -O /tmp/$file
#sudo VBoxManage extpack uninstall "Oracle VM VirtualBox Extension Pack"
sudo VBoxManage extpack install /tmp/$file --replace

#run python script to create the VirtualBox Guest
python buildVMXP.py cuckoo1

#set up IP and forwarding
sudo iptables -A FORWARD -o eth0 -i vboxnet0 -s 192.168.56.0/24 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A POSTROUTING -t nat -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1


