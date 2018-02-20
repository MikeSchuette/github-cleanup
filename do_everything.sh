#!/bin/bash
set -e

# Runs everything with default settings (clone to ./repos, output to ./stats/TODAY)


### Config ###
# TODO getopt

### Init ###

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #location of this script, for generating absolute paths
TIMESTAMP=$(date +"%Y%m%d")
STATS_DIR="$MY_DIR/stats/$TIMESTAMP"
REPOS_DIR="$MY_DIR/repos"

if [ -z "$GITHUB_ORG" ]; then
  echo "You must set environment variable GITHUB_ORG, aborting."
  exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "You must set environment variable GITHUB_TOKEN, aborting."
  exit 1
fi

if [ ! -x "./listallrepos" ]; then
  echo "./listallrepos is not executable, aborting."
  exit 1
fi

if [ ! -x "./git_all.sh" ]; then
  echo "./git_all.sh is not executable, aborting."
  exit 1;
fi

if [ ! -x "./calculate_staleness.sh" ]; then
  echo "./calculate_staleness.sh is not executable, aborting."
  exit 1;
fi

# jq might be in ./ or might be on path
JQ_CMD='./jq'
if [ ! -x "$JQ_CMD" ]; then
  command -v jq >/dev/null 2>&1 || {
    echo "I require jq but it's not installed, aborting.";
    exit 1;
  }
  JQ_CMD='jq'
fi


### Main ###

echo "Stats dir is $STATS_DIR"
if [ ! -d "$STATS_DIR" ]; then
  echo "Stats dir doesn't exist, creating..."
  mkdir -p "$STATS_DIR"
  if [ $? -ne 0 ] ; then
    echo "Unable to mkdir, aborting."
    exit 1
  fi
fi

echo "Repos dir is $REPOS_DIR"
if [ ! -d "$REPOS_DIR" ]; then
  echo "Repos dir doesn't exist, creating..."
  mkdir -p "$REPOS_DIR"
  if [ $? -ne 0 ] ; then
    echo "Unable to mkdir, aborting."
    exit 1
  fi
fi

echo "Getting full repo list ..."
./listallrepos > "$STATS_DIR/allrepos.json"
if [ $? -ne 0 ] ; then
  echo "There was an error in listallrepos, aborting."
  exit 1
fi

#Ignore repos created in the past 14 days (60 * 60 * 24 * 14 = 1209600)
echo "Filtering to exclude recently-created repos ..."
< "$STATS_DIR/allrepos.json" "$JQ_CMD" '[.[] | select((now - (.created_at | fromdate)) >= 1209600)]' > "$STATS_DIR/allrepos-exclude-recent.json"

# Everything downstream runs off of this file (instead of just globbing the
# directories) so that we can easily implement a whitelist / more metadata /
# etc here.
DATA_FILE="$STATS_DIR/ssh_urls"
echo "Extracting git data ..."
< "$STATS_DIR/allrepos-exclude-recent.json" "$JQ_CMD" -r '.[] | .ssh_url' > "$DATA_FILE"

echo "Cloning and pulling all ..."
./git_all.sh "$DATA_FILE" "$REPOS_DIR"

./calculate_staleness.sh "$DATA_FILE" "$REPOS_DIR" "$STATS_DIR/$TIMESTAMP.csv"
