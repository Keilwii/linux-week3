#!/usr/bin/env bash
# week 3: collect basic server status info and write it as an html page
#
# usage:
#   ./report.sh              generate the report into $OUT_DIR
#   ./report.sh --test 90    only print the disk status for a given percentage

set -euo pipefail

OUT_DIR="${OUT_DIR:-/var/www/week-1/viikko3}"
GITHUB_URL="https://github.com/Keilwii/linux-week3"
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

if [[ "${1:-}" == "--test" ]]; then
    echo "$2% -> $(disk_status "$2")"
    exit 0
fi

GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z (UTC%:z)')
UPTIME_TEXT="$(uptime -p | sed 's/^up //') (booted $(uptime -s))"

DISK_PCT=$(disk_usage_pct)
DISK_USED=$(df -h --output=used / | tail -1 | tr -d ' ')
DISK_SIZE=$(df -h --output=size / | tail -1 | tr -d ' ')
DISK_AVAIL=$(df -h --output=avail / | tail -1 | tr -d ' ')
DISK_USAGE="$DISK_PCT% ($DISK_USED used of $DISK_SIZE, $DISK_AVAIL free)"
DISK_STATUS=$(disk_status "$DISK_PCT")

MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')

mkdir -p "$OUT_DIR"
chmod 755 "$OUT_DIR"
TEMP_FILE=$(mktemp "$OUT_DIR/.index.XXXXXX")

cat > "$TEMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Week 3 – Server Status Report</title>
    <style>
        body {
            font-family: system-ui, sans-serif;
            max-width: 900px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
            background: #eef3ec;
            color: #1c2a1f;
        }

        h1, h2 {
            color: #2d5a35;
        }

        h1 {
            font-family: "Courier New", monospace;
        }

        section {
            margin: 24px 0;
            padding: 24px;
            background: white;
            border-radius: 12px;
            border-left: 5px solid #6a9f6f;
        }

        .table-container {
            overflow-x: auto;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        th, td {
            border: 1px solid #c9d6c6;
            padding: 12px;
            text-align: left;
        }

        th {
            background: #dcebd8;
        }

        code {
            background: #e3e9e0;
            padding: 2px 5px;
            border-radius: 4px;
            overflow-wrap: anywhere;
        }

        a {
            color: #1f6b3a;
        }

        .note {
            color: #5a6b5c;
        }
    </style>
</head>
<body>
    <header>
        <h1>Server Status Report</h1>
        <p>Week 3: Linux command line and Bash scripting</p>
        <p>
            This is my cPouta VM (dev-kalle). The same machine still runs my week 1 page and the
            week 2 visit counter. Below is a status report that a Bash script writes every minute,
            and after that my notes on how I made it and how I tested it.
        </p>
    </header>

    <section>
        <h2>Current server status</h2>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Information</th>
                        <th scope="col">Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <th scope="row">Report generated</th>
                        <td>$GENERATED_AT</td>
                    </tr>
                    <tr>
                        <th scope="row">Server uptime</th>
                        <td>$UPTIME_TEXT</td>
                    </tr>
                    <tr>
                        <th scope="row">Root filesystem disk usage</th>
                        <td>$DISK_USAGE</td>
                    </tr>
                    <tr>
                        <th scope="row">Disk space status</th>
                        <td><strong>$DISK_STATUS</strong></td>
                    </tr>
                    <tr>
                        <th scope="row">Total RAM</th>
                        <td>$MEM_TOTAL MiB</td>
                    </tr>
                    <tr>
                        <th scope="row">Available RAM</th>
                        <td>$MEM_AVAILABLE MiB</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <p>
            Disk space status is <strong>OK</strong> below 80% usage
            and <strong>WARNING</strong> at 80% or above.
        </p>

        <p class="note">
            Bash generates this report once per minute.
            Wait approximately 1–2 minutes and reload the page
            to see a new generation time.
        </p>
    </section>

    <section>
        <h2>Commands used</h2>
        <ul>
            <li>
                <code>date '+%Y-%m-%d %H:%M:%S %Z'</code>:
                displays the current date, time and time zone
                using the format specified in the script. The server runs in UTC.
            </li>
            <li>
                <code>uptime -p</code>:
                displays how long the server has been running in plain words.
                <code>uptime -s</code> gives the boot time.
            </li>
            <li>
                <code>df -P / | awk 'NR == 2 {print &#36;5}'</code>:
                passes filesystem information to awk, which extracts
                the usage percentage from the second row (the first row is the header).
                In the script awk also removes the % sign so the number can be compared.
            </li>
            <li>
                <code>free -m | awk '/^Mem:/ {print &#36;2, &#36;7}'</code>:
                <code>free -m</code> displays memory information in mebibytes (MiB),
                and awk picks the Mem line and prints the total (column 2) and available (column 7) RAM.
            </li>
            <li>
                <code>crontab -l</code>:
                shows my crontab, to check that the schedule is installed.
            </li>
        </ul>
    </section>

    <section>
        <h2>How the script works</h2>
        <p>
            The script collects server information using Linux commands
            and stores the results in Bash variables through command
            substitution. A function uses an if statement to determine
            the disk space status.
        </p>
        <p>
            The script generates a temporary HTML file and then moves
            the completed file into place as index.html.
            Nginx serves this file at /viikko3/.
            Nginx already served <code>/var/www/week-1</code> from week 1, so writing into
            <code>/var/www/week-1/viikko3/</code> was enough and I didn't have to change the nginx config.
        </p>
        <p>
            The function <code>disk_status</code> takes the usage percentage as an argument.
            <code>if (( pct &gt;= 80 ))</code> prints WARNING, otherwise it prints OK.
            The real percentage comes from the function <code>disk_usage_pct</code>, which is a pipe:
            <code>df -P / | awk 'NR==2 {gsub("%", "", &#36;5); print &#36;5}'</code>.
            df lists the root filesystem, awk takes the second line, removes the % sign from column 5 and prints the number.
            Running <code>./report.sh --test 90</code> only prints the status for the given number,
            so I can test the logic without touching the real value.
        </p>
    </section>

    <section>
        <h2>Scheduling</h2>
        <p>
            I used cron. My user crontab has the line
            <code>* * * * * /home/kalle/linux-week3/report.sh</code>,
            which runs the script every minute. Errors go to <code>~/status-cron.log</code>.
            The cron service is enabled in systemd (<code>systemctl is-enabled cron</code> says enabled),
            so it starts on boot and the crontab keeps working after a reboot.
            The crontab line is saved in the repo as <code>crontab.txt</code> and installed with
            <code>crontab crontab.txt</code>.
        </p>
    </section>

    <section>
        <h2>Test results</h2>

        <h3>Syntax check and manual execution</h3>
        <p>
            <code>bash -n report.sh</code> gave no output, so there were no syntax errors.
            Running <code>./report.sh</code> by hand created the page, and in the browser all the values
            were there with the right units.
        </p>

        <h3>Disk space status tests</h3>
        <p>
            I gave the status function test values with <code>./report.sh --test 50</code> and so on.
            The test values only go into the function in test mode, so the real report always uses the
            real disk usage from df (3%, status OK).
        </p>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Test input</th>
                        <th scope="col">Expected status</th>
                        <th scope="col">Actual status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>50%</td>
                        <td>OK</td>
                        <td>OK</td>
                    </tr>
                    <tr>
                        <td>80%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                    <tr>
                        <td>90%</td>
                        <td>WARNING</td>
                        <td>WARNING</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <h3>Automatic updates</h3>
        <p>
            After installing the crontab on 15 Nov 2026 the generation time changed by itself:
            09:40:59 (my manual run) &rarr; 09:42:01 &rarr; 09:43:01 &rarr; 09:44:01 UTC.
        </p>

        <h3>Reboot test</h3>
        <p>
            I rebooted the VM with <code>sudo reboot</code> on 15 Nov 2026, actually twice, at 09:46 and 09:49 UTC.
            I didn't start anything by hand afterwards. The week 2 app opened and its counter continued,
            and this page opened too. The uptime row showed the new boot time, and the report kept updating:
            09:47:02 &rarr; 09:48:01 after the first reboot, and 09:50:01 &rarr; 09:51:01 &rarr; 09:52:01 after the second.
            cron and nginx were both active and the error log was empty.
        </p>
    </section>

    <section>
        <h2>A problem solved or a lesson learned</h2>
        <p>
            I used <code>mktemp</code> for the temporary file, but mktemp creates files with permissions
            <code>600</code> (only the owner can read). Nginx runs as www-data, so it can't read a file like that.
            I tested it with a file made by mktemp: the browser got 403 Forbidden, and after
            <code>chmod 644</code> it loaded fine. So the script runs <code>chmod 644</code> on the temporary
            file before moving it into place. I learned that the file permissions matter even when the folder is readable.
        </p>
    </section>

    <footer>
        <p><a href="$GITHUB_URL">View the source code on GitHub</a></p>
    </footer>
</body>
</html>
EOF

# mktemp makes the file 600, nginx needs to be able to read it
chmod 644 "$TEMP_FILE"
mv -f "$TEMP_FILE" "$OUT_DIR/index.html"
