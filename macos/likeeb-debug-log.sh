#!/bin/sh
# Пишет журнал отладочной правой половины по USB в файл с метками времени.
# После перезагрузки клавиатуры ждёт её порт и продолжает.
log="${1:-$HOME/Library/Logs/likeeb-debug.log}"
while true; do
    port=$(ls /dev/cu.usbmodem* 2>/dev/null | head -1)
    if [ -z "$port" ]; then sleep 0.2; continue; fi
    echo "=== $(date '+%F %T') порт $port" >> "$log"
    stty -f "$port" raw 115200 2>/dev/null
    cat "$port" | perl -MPOSIX -pe '$|=1; $_ = strftime("%T ", localtime) . $_' >> "$log"
    echo "=== $(date '+%F %T') порт пропал" >> "$log"
done
