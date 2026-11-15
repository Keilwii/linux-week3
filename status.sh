#!/usr/bin/env bash
# week 3: collect basic server status info

generated=$(date '+%Y-%m-%d %H:%M:%S')
timezone=$(date '+%Z (UTC%:z)')
uptime_text=$(uptime -p | sed 's/^up //')
boot_time=$(uptime -s)
disk_pct=$(df -P / | awk 'NR==2 {gsub("%", "", $5); print $5}')
mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_avail=$(free -m | awk '/^Mem:/ {print $7}')

echo "Generated: $generated $timezone"
echo "Uptime:    $uptime_text (since $boot_time)"
echo "Disk /:    $disk_pct %"
echo "RAM:       $mem_avail MB available of $mem_total MB"
