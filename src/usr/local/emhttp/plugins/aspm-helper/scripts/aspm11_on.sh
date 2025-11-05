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

sed -i 's/^aspm_11_state=.*/aspm_11_state="AUTOSTART IS ON"/' /boot/config/plugins/aspm-helper/aspmhelpersettings

cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm11.sh /usr/local/emhttp/plugins/aspm-helper/autostart/aspm11.sh
chmod +x /usr/local/emhttp/plugins/aspm-helper/autostart/aspm11.sh
cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm11.sh /boot/config/plugins/aspm-helper/autostart/aspm11.sh

echo "ASPM 11 Autostart enabled"
