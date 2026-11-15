#!/usr/bin/env bash
# week 3: collect basic server status info and write it as an html page
#
# usage:
#   ./status.sh              generate the report into $OUT_DIR
#   ./status.sh --test 90    only print the disk status for a given percentage

set -euo pipefail

OUT_DIR="${OUT_DIR:-/var/www/week-1/viikko3}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
WARN_LIMIT=80

# OK below the limit, WARNING at or above it
disk_status() {
    local pct=$1
    if (( pct >= WARN_LIMIT )); then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# root filesystem usage as a plain number, e.g. "3"
disk_usage_pct() {
    df -P / | awk 'NR==2 {gsub("%", "", $5); print $5}'
}

# MB -> "7.6 GB"
to_gb() {
    awk -v mb="$1" 'BEGIN {printf "%.1f GB", mb / 1024}'
}

if [[ "${1:-}" == "--test" ]]; then
    echo "$2% -> $(disk_status "$2")"
    exit 0
fi

generated=$(date '+%Y-%m-%d %H:%M:%S')
timezone=$(date '+%Z (UTC%:z)')
uptime_text=$(uptime -p | sed 's/^up //')
boot_time=$(uptime -s)

disk_pct=$(disk_usage_pct)
disk_size=$(df -h --output=size / | tail -1 | tr -d ' ')
disk_used=$(df -h --output=used / | tail -1 | tr -d ' ')
disk_avail=$(df -h --output=avail / | tail -1 | tr -d ' ')
status=$(disk_status "$disk_pct")

mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_avail=$(free -m | awk '/^Mem:/ {print $7}')

if [[ "$status" == "OK" ]]; then
    status_class="ok"
else
    status_class="warn"
fi

mkdir -p "$OUT_DIR"
chmod 755 "$OUT_DIR"
# static files (css, docs page) live in the repo
install -m 644 "$SCRIPT_DIR"/site/* "$OUT_DIR"/

tmp=$(mktemp "$OUT_DIR/.index.XXXXXX")

cat > "$tmp" <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="60">
<title>week 3 - server status</title>
<link rel="stylesheet" href="style.css">
</head>
<body>

<h1>server status</h1>
<p class="sub">dev-kalle &middot; updated by cron every minute</p>

<table>
  <tr><th>Report generated</th><td>$generated</td></tr>
  <tr><th>Time zone</th><td>$timezone</td></tr>
  <tr><th>Uptime</th><td>$uptime_text (booted $boot_time)</td></tr>
  <tr><th>Disk usage /</th><td>$disk_pct % ($disk_used used of $disk_size, $disk_avail free)</td></tr>
  <tr><th>Disk status</th><td><span class="$status_class">$status</span></td></tr>
  <tr><th>RAM total</th><td>$mem_total MB ($(to_gb "$mem_total"))</td></tr>
  <tr><th>RAM available</th><td>$mem_avail MB ($(to_gb "$mem_avail"))</td></tr>
</table>

<p class="links"><a href="docs.html">how this works + tests</a> &middot;
<a href="https://github.com/Keilwii/linux-week3">code on GitHub</a></p>

</body>
</html>
HTML

# mktemp makes the file 600, nginx needs to be able to read it
chmod 644 "$tmp"
mv -f "$tmp" "$OUT_DIR/index.html"
