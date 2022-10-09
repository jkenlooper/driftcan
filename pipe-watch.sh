#!/usr/bin/env -S sh -e

# https://unix.stackexchange.com/questions/65891/how-to-execute-a-shellscript-when-i-plug-in-a-usb-device

pipe="/tmp/driftcan-pipe"
remote_path="/media/$USER/driftcan"
max_timeout=30

do_synchronization() {
  printf "\n\n%s\n\n" "Starting backup for $remote_path"
  notify-send --urgency critical --expire-time=7000 "Starting backup for $remote_path"
  (
  cd "$remote_path"
  make
  make clone
  )
  printf "\n\n%s\n\n" "Finished backup for $remote_path"
  notify-send --urgency critical --expire-time=7000 "Finished backup for $remote_path"
}

if [ ! -p "$pipe" ]; then
  # The pipe file is only created in udev rule.
  # TODO Should not use sudo here. These commands should be executed separately
  # from this script.
  sudo cp zz-10-driftcan.rules /etc/udev/rules.d/zz-10-driftcan.rules
  sudo udevadm control --reload
fi

#If the disk is already plugged on startup, do a sync
if [ -e "$remote_path" ]; then
  do_synchronization
fi

# Make the permanent loop to watch the usb connection
while true; do
  if read line < "$pipe"; then
    # Test the message read from the fifo
    if [ "$line" = "connected" ]; then
      echo "Waiting $max_timeout seconds for $remote_path to exist"
      # The usb has been plugged, wait for disk to be mounted
      timeout_count="1"
      while [ ! -e "$remote_path" ]; do
        if [ "$timeout_count" -gt "$max_timeout" ]; then
          break
        fi
        timeout_count="$((timeout_count+1))"
        printf "."
        sleep 1
      done
      if [ "$timeout_count" -le "$max_timeout" ]; then
        do_synchronization
      else
        printf "\n\n%s\n" "Timed out waiting for $remote_path"
      fi
    else
      echo "Unhandled message from fifo : [$line]"
    fi
  fi
done
echo "Reader exiting"
