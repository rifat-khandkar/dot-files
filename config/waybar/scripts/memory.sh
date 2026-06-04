#!/bin/bash
free | awk '/^Mem:/{used=$3/1048576; pct=$3/$2*100; cls="normal"; if(used>8) cls="critical"; if(pct>30 && cls=="normal") cls="warning"; printf "{\"text\": \" %.1f GiB\", \"class\": \"%s\"}\n", used, cls}'
