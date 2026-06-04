#!/bin/bash
case "$1" in
  mouse)
        failures=0
        while true; do
          OUTPUT=$(/home/rifat/.config/waybar/scripts/mouse-battery 2>/dev/null)
          if [ $? -eq 0 ]; then
            failures=0
            echo "$OUTPUT"
          else
            failures=$((failures + 1))
            if [ $failures -ge 1 ]; then
              printf '{"text": "", "class": "hidden"}\n'
            fi
          fi
      sleep 0.03
    done
    ;;
  headset)
    failures=0
    while true; do
      PCT=$(timeout 2 upower -d 2>/dev/null | awk '/headset/,/percentage/' | grep percentage | awk '{print $2}' | tr -d '%')
      if [ -z "$PCT" ]; then
        failures=$((failures + 1))
        if [ $failures -ge 3 ]; then
          printf '{"text": "", "class": "hidden"}\n'
        fi
      else
        failures=0
        ICON=$(printf '\xef\x89\x80')
        [ "$PCT" -lt 80 ] && ICON=$(printf '\xef\x89\x81')
        [ "$PCT" -lt 60 ] && ICON=$(printf '\xef\x89\x82')
        [ "$PCT" -lt 40 ] && ICON=$(printf '\xef\x89\x83')
        [ "$PCT" -lt 20 ] && ICON=$(printf '\xef\x89\x84')
        CLASS="normal"
        [ "$PCT" -le 40 ] && CLASS="warning"
        [ "$PCT" -lt 30 ] && CLASS="critical"
        printf '{"text": "%s %d%%", "tooltip": "realme Buds T300: %d%%", "class": "%s"}\n' "$ICON" "$PCT" "$PCT" "$CLASS"
      fi
      sleep 1
    done
    ;;
esac
