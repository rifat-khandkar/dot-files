#!/bin/bash
failures=0
while true; do
  PCT=$(/home/rifat/.config/waybar/scripts/mouse-usb-battery 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$PCT" ]; then
    failures=0
    printf '{"text": " %s%%", "class": "charging"}\n' "$PCT"
  else
    failures=$((failures + 1))
    if [ $failures -ge 2 ]; then
      printf '{"text": "", "class": "hidden"}\n'
    fi
  fi
  sleep 0.05
done
