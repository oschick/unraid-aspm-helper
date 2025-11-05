#!/bin/bash

source /boot/config/plugins/aspm-helper/aspmhelpersettings

###############

if [ "$syslog" == "yes" ]; then

log_message() {
  while IFS= read -r line; do
    logger "aspm-helper: ${line}"
  done
}
exec > >(log_message) 2>&1

fi

###############

sed -i 's/^aspm_19_state=.*/aspm_19_state="AUTOSTART IS ON"/' /boot/config/plugins/aspm-helper/aspmhelpersettings

cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm19.sh /usr/local/emhttp/plugins/aspm-helper/autostart/aspm19.sh
chmod +x /usr/local/emhttp/plugins/aspm-helper/autostart/aspm19.sh
cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm19.sh /boot/config/plugins/aspm-helper/autostart/aspm19.sh

echo "ASPM 19 Autostart enabled"
