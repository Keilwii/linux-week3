# linux-week3

Week 3 assignment: bash script that writes a server status report as html, run by cron every minute.

Page: http://46.62.229.94/viikko3/

- `report.sh` - the script (`./report.sh --test 90` only prints the disk status for 90 %)
- `crontab.txt` - the cron schedule
- the page html (with my notes) is generated inside `report.sh`

Setup on the server:

```
git clone https://github.com/Keilwii/linux-week3.git ~/linux-week3
crontab ~/linux-week3/crontab.txt
```
