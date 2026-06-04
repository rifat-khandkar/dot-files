#!/bin/bash
if ! rfkill list bluetooth 2>/dev/null | grep -q "Bluetooth"; then
  printf '{"text": "", "class": "hidden"}\n'
  exit 0
fi
if rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
  printf '{"text": "", "class": "off"}\n'
  exit 0
fi
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
  printf '{"text": "", "class": "off"}\n'
  exit 0
fi
if bluetoothctl devices Connected 2>/dev/null | grep -q "^Device"; then
  printf '{"text": "", "class": "connected"}\n'
else
  printf '{"text": "", "class": "on"}\n'
fi
