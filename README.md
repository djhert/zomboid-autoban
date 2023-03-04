# Project Zomboid Autoban script

A small script to inject a list of known SteamIDs into the banned list for Project Zomboid.

```
zomboid-autoban.sh - Project Zomboid Auto-Blocklist Manager
Usage: ./zomboid-autoban.sh [OPTIONS] /path/to/server.db

Available Options:
  -h|--help             Show this help and exit
  -u|--update           Update block list
  -v|--version          Show version info, credits, and exit
```

The file `banned.list` can be retrieved from a custom source by modifying the variable `UPDATEURL` in the script

The `banned.list` file should be in the format of:
```
# comments are allowed and ignored
## no space between the SteamID and the optional Reason
SteamID,Reason(optional)
# if no reason, can have a comma or not; doesn't matter
SteamID
SteamID,
```

## Recommended usage

Set this up as a cron job that runs daily

Check your server's OS documentation for how to setup cron.

**Common:**
- [Ubuntu](https://help.ubuntu.com/community/CronHowto)
- [Fedora](https://docs.fedoraproject.org/en-US/fedora/latest/system-administrators-guide/monitoring-and-automation/Automating_System_Tasks/)

Example to run this daily at midnight:
```bash
pzuser@server $ crontab -l
0 0 * * * /home/pzuser/zomboid-autoban.sh -u /home/pzuser/Zomboid/db/SERVERNAME.db
```

Two backups are maintained of the SQLite database by this script with the names `.1` and `.2` at the same location.

