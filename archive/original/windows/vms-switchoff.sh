#!/bin/bash

# Iterate through VMs in random order
/usr/bin/shuf -i 0-5 | while read number; do

  # Send VM shutdown signal
  /usr/bin/vboxmanage list runningvms | /usr/bin/grep --quiet \"Win10-Ghosts-$number && /usr/bin/VBoxManage controlvm "Win10-Ghosts-$number" acpipowerbutton

done

# Pause 1 min to allow shutdown
/usr/bin/sleep 60

# Iterate through VMs again in random order
/usr/bin/shuf -i 0-5 | while read number; do

  # If still running, force power off
  /usr/bin/vboxmanage list runningvms | /usr/bin/grep --quiet \"Win10-Ghosts-$number && /usr/bin/VBoxManage controlvm "Win10-Ghosts-$number" poweroff

done
