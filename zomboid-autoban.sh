#!/bin/bash

## Customize this to your own maintained list, or keep the default
UPDATEURL=""

# Quick check, sqlite and curl are required
if ! command -v sqlite3 &> /dev/null; then
        echo "ERROR: sqlite3 could not be found. Please install sqlite3"
        exit 1
fi

if ! command -v curl &> /dev/null; then
        echo "ERROR: curl could not be found. Please install curl"
        exit 1
fi

# If there is no input, exit
[[ $# -lt 1 ]] && echo "ERROR: No input given.  Try: '$0 --help'" && exit 1

# Print version
## If you make a change to this script, please increment the Version below
### Also, make sure to add yourself to the credits!!!
version() {
        cat << EOF
$0 - v1.0
Credits: dhert
EOF
}

# help function
usage() {
        cat << EOF
$0 - Project Zomboid Auto-Blocklist Manager
Usage: $0 [OPTIONS] /path/to/server.db

Available Options:
  -h|--help             Show this help
  -u|--update           Update block list
  -v|--version          Show version info and credits
EOF
}

# Some settings
UPDATE=0
FILE=""

# Handle our input
while [ "$1" != "" ]; do
        case $1 in
                -u | --update)
                UPDATE=1;;
                -h | --help)
                        usage
                        exit 0;;
                -v | --version)
                        version
                        exit 0;;
                *)
                        FILE="$1"
                        break;;
        esac
        shift
done

# Quick check if our file exists and is an SQLite Database
[[ `file $FILE 2>/dev/null | grep SQLite &>/dev/null; echo $?` -ne 0 ]] && echo "ERROR: $1 does not exist or is not an SQLite Database" && exit 1

# Quick check if our file has our required tables
[[ `sqlite3 $FILE "SELECT EXISTS (SELECT * FROM sqlite_master WHERE type='table' AND name='bannedid')"` -ne 1 ]] && echo "ERROR: $FILE is not a Project Zomboid World database" && exit 1

LIST="$(realpath $(dirname $0))/banned.list"
# Check if we don't have a list or need to download it
if [[ ! -f $LIST ]] || [[ $UPDATE -gt 0 ]]; then
        if [[ $UPDATEURL != "" ]]; then
                curl -s "$UPDATEURL" --output $LIST
        else
                echo "Skipping"
        fi
fi

# Final check for our list, just in case
[[ ! -f $LIST ]] && echo "ERROR: Banned list $LIST does not exist and could not be downloaded" && exit 1

# Make some backups
## First, remove the oldest
rm -f $FILE.2 2>/dev/null

## Move the backup to part 2
mv -f $FILE.1 $FILE.2 2>/dev/null

## Now, the current to the backup
cp -f $FILE $FILE.1

# Read our file line by line
while read -r line; do
        # Skip the line if its a blank variable, a blank line, or it starts with "#"
        ([[ -z "$line" ]] || [[ "$line" == "" ]] || [[ $line =~ ^#.* ]]) && continue
        # Cut by comma, index 1
        ID=$(echo $line | cut -d',' -f1)
        # Cut by comma, index 2
        reason=$(echo $line | cut -d',' -f2)
        # If they are equal, then there was probably no reason given
        if [[ "$ID" == "$reason" ]]; then
                reason=""
        fi

        case "$ID" in
        # Check if the $ID is all numbers or blank. if not, then its likely not a steam id
        ("" | *[!0-9]*)
                ## This should always be an error, and the admin should be notified if cron
                echo "ERROR: $ID is not a valid SteamID, could be a corrupted file.";;
        *)
                ## Add the user to the sqlite3 database if its not already there
                sqlite3 $FILE "INSERT INTO bannedid(steamid, reason) SELECT $ID, \"$reason\" WHERE NOT EXISTS(SELECT 1 FROM bannedid WHERE steamid = $ID)"
        esac
done < $LIST
# We're done!