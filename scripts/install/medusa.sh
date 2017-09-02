#! /bin/bash
# Medusa installer for swizzin
# Author: liara

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi
distribution=$(lsb_release -is)
user=$(cat /root/.master.info | cut -d: -f1)

apt-get -y -q update >> $log 2>&1
apt-get -y -q install git-core openssl libssl-dev python2.7 >> $log 2>&1

function _rar() {
  if [[ -z $(which rar) ]]; then
    cd /tmp
    wget -q http://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
    tar -xzf rarlinux-x64-5.5.0.tar.gz >/dev/null 2>&1
    cp rar/*rar /bin >/dev/null 2>&1
    rm -rf rarlinux*.tar.gz >/dev/null 2>&1
    rm -rf /tmp/rar >/dev/null 2>&1
  fi
}

if [[ $distribution == "Debian" ]]; then
  _rar
else
  apt-get -y install rar unrar >>$log 2>&1 || echo "INFO: Could not find rar/unrar in the repositories. It is likely you do not have the multiverse repo enabled. Installing directly."; _rar
fi

cd /home/${user}/
git clone https://github.com/pymedusa/Medusa.git .medusa
chown -R ${user}:${user} .medusa

cat > /etc/systemd/system/medusa@.service <<MSD
[Unit]
Description=Medusa
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=%I
Group=%I
ExecStart=/usr/bin/python /home/%I/.medusa/SickBeard.py -q --daemon --nolaunch --datadir=/home/%I/.medusa
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
MSD

systemctl enable medusa@${user} >>$log 2>&1


if [[ -f /install/.nginx.lock ]]; then
  systemctl start medusa@${user}
  systemctl stop medusa@${user}
  bash /usr/local/bin/swizzin/nginx/medusa.sh
  service nginx reload
fi
systemctl start medusa@${user}

touch /install/.medusa.lock
