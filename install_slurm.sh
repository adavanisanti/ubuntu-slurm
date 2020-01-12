#!/bin/bash
INSTALL_DIR=/tmp
apt-get update
apt-get install -y git gcc make ruby ruby-dev libpam0g-dev libmariadb-client-lgpl-dev libmysqlclient-dev
gem install fpm
apt-get install -y libmunge-dev libmunge2 munge
systemctl enable munge
systemctl start munge

echo "Testing Munge"
munge -n | unmunge | grep STATUS

cd $INSTALL_DIR
git clone https://github.com/adavanisanti/ubuntu-slurm.git

cd $INSTALL_DIR
wget https://download.schedmd.com/slurm/slurm-17.11.12.tar.bz2
tar xvjf slurm-17.11.12.tar.bz2
cd slurm-17.11.12
./configure --prefix=/tmp/slurm-build --sysconfdir=/etc/slurm --enable-pam --with-pam_dir=/lib/x86_64-linux-gnu/security/ --without-shared-libslurm
make
make contrib
make install
cd ..
fpm -s dir -t deb -v 1.0 -n slurm-17.11.12 --prefix=/usr -C /tmp/slurm-build .
dpkg -i slurm-17.11.12_1.0_amd64.deb
useradd slurm 
mkdir -p /etc/slurm /etc/slurm/prolog.d /etc/slurm/epilog.d /var/spool/slurm/ctld /var/spool/slurm/d /var/log/slurm
chown slurm /var/spool/slurm/ctld /var/spool/slurm/d /var/log/slurm

cd $INSTALL_DIR
cp ubuntu-slurm/slurmdbd.service /etc/systemd/system/
cp ubuntu-slurm/slurmctld.service /etc/systemd/system/
mkdir -p /mnt/resource/slurm/
chmod +x slurm.conf.sh
bash slurm.conf.sh >> /etc/slurm/slurm.conf
echo "NodeName=dummy-compute" >> /mnt/resource/slurm/cluster.conf

systemctl enable slurmctld
systemctl start slurmctld


