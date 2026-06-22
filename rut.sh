#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root! Type 'sudo su' first." 1>&2
   exit 1
fi

clear
wget -q -O /tmp/sshd_config https://raw.githubusercontent.com/dudul19/root-access/main/sshd_config && sudo mv /tmp/sshd_config /etc/ssh/sshd_config
systemctl restart ssh

clear
echo "======================================"
echo " ❖ Create Root Access"
echo "--------------------------------------"
read -p " New Password : " pwe

usermod -p "$(perl -e "print crypt('$pwe', 'Q4')")" root;

clear
echo "======================================"
echo " ❖ Detail VPS"
echo "--------------------------------------"
echo " Please save the following data!"
echo "--------------------------------------"
echo " IP Address : $(curl -Ls http://ipinfo.io/ip)"
echo " Username   : root"
echo " Password   : $pwe"
echo "======================================"
echo
read -n 1 -s -r -p "Press any key to exit"
exit
