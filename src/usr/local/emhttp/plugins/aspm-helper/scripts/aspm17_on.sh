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

sed -i 's/^aspm_17_state=.*/aspm_17_state="AUTOSTART IS ON"/' /boot/config/plugins/aspm-helper/aspmhelpersettings

cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm17.sh /usr/local/emhttp/plugins/aspm-helper/autostart/aspm17.sh
chmod +x /usr/local/emhttp/plugins/aspm-helper/autostart/aspm17.sh
cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm17.sh /boot/config/plugins/aspm-helper/autostart/aspm17.sh

echo "ASPM 17 Autostart enabled"
