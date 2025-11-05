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

sed -i 's/^aspm_18_state=.*/aspm_18_state="AUTOSTART IS OFF"/' /boot/config/plugins/aspm-helper/aspmhelpersettings

rm /usr/local/emhttp/plugins/aspm-helper/autostart/aspm18.sh
rm /boot/config/plugins/aspm-helper/autostart/aspm18.sh

echo "Autostart disabled for ASPM 18"
