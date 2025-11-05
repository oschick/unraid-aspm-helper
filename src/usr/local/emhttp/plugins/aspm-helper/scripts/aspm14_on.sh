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

sed -i 's/^aspm_14_state=.*/aspm_14_state="AUTOSTART IS ON"/' /boot/config/plugins/aspm-helper/aspmhelpersettings

cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm14.sh /usr/local/emhttp/plugins/aspm-helper/autostart/aspm14.sh
chmod +x /usr/local/emhttp/plugins/aspm-helper/autostart/aspm14.sh
cp /usr/local/emhttp/plugins/aspm-helper/scripts/aspm14.sh /boot/config/plugins/aspm-helper/autostart/aspm14.sh

echo "ASPM 14 Autostart enabled"
