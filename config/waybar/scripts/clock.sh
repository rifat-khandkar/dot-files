#!/bin/bash
H=$(date +%H)
CLS="normal"
if [ "$H" -ge 23 ] || [ "$H" -lt 9 ]; then
  CLS="night"
fi
printf '{"text": "  %s", "class": "%s"}\n' "$(date '+%I:%M %p')" "$CLS"
