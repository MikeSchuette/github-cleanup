#!/bin/bash
set -e

# config
MJS_DEBUG=false
OLD_AGE_DAYS=1095
FEW_FILES=10
TINY_KB=8



STATS_FILE=$1
NOW=$(date +%s)
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #location of this script
REPOS_DIR="$MY_DIR/repos"
DATA_FILE="${MY_DIR}/ssh_urls"

usage() {
  echo "USAGE: $0 <filename.csv>"
  echo
  echo "This script assumes that all repos exist in ./repos and have already been"
  echo "cloned / pulled with the latest branch."
  exit 1
}


# Quick n dirty!  Global vars!
writeRepoStats() {
  LINE=${HEAT},"\"https://github.com/TheWeatherCompany/${REPO_NAME}\",\"${HEAT_REASON}\",\"${LAST_COMMIT_BRANCH}\",\"${LAST_COMMIT_DATE}\",${NUM_COMMITS},${NUM_FILES},${DISK_SIZE_CONTENT}"
  if $MJS_DEBUG; then
    echo $LINE
    echo;
  else
    echo $LINE >> "$MY_DIR/$STATS_FILE"
  fi
}


### Begin main ###


if [[ -z "$STATS_FILE" ]]; then usage; fi
NUM_REPOS=$(wc -l "$DATA_FILE" | awk '{print $1}')

#Write CSV header into new file
if ! $MJS_DEBUG ; then
  echo '"Heat","Repo URL","Heat Reasons","Latest branch","Last commit date","Number of commits","Number of files","Size of repo content (kb)"' > "$MY_DIR/$STATS_FILE"
fi

CURRENT_NUM=0
while read REPO_URL; do
  CURRENT_NUM=$((++CURRENT_NUM))

  REPO_NAME=$(basename "$REPO_URL" .git)
  echo "${CURRENT_NUM}/${NUM_REPOS} $REPO_NAME"

  #sanity check
  REPO_DIR="$REPOS_DIR/$REPO_NAME"
  if [[ ! -d "$REPO_DIR" ]]; then
    echo "Not a directory: '${REPO_DIR}', skipping"
    continue
  fi
  #init
  HEAT=0
  HEAT_REASON=''
  NUM_COMMITS=0
  LAST_COMMIT_DATE=''
  LAST_COMMIT_UNIX=0
  LAST_COMMIT_AGE=0
  LAST_COMMIT_BRANCH=''
  NUM_FILES=0
  DISK_SIZE_ACTUAL=0
  DISK_SIZE_GIT=0
  DISK_SIZE_CONTENT=0
  NUM_BRANCHES=0

  cd "$REPO_DIR"
  if ! git --no-pager log -1 >/dev/null 2>&1; then
    # No git log (non-zero error) = totally empty
    HEAT=100
    HEAT_REASON='completely empty'
    LAST_COMMIT_DATE='never'
    writeRepoStats
    continue
  fi
  LAST_COMMIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  NUM_COMMITS=$(git rev-list --count HEAD --)
  LAST_COMMIT_DATE=$(git --no-pager log -1 --format=%cI)
  LAST_COMMIT_UNIX=$(git --no-pager log -1 --format=%ct)
  LAST_COMMIT_AGE=$((($NOW - $LAST_COMMIT_UNIX) / 86400 )) #age in days
  NUM_FILES=$(find . -type f | grep -v '.git/' | wc -l | awk '{print $1}')
  DISK_SIZE_ACTUAL=$(du -k -s . | awk '{print $1}')
  DISK_SIZE_GIT=$(du -k -s .git | awk '{print $1}')
  DISK_SIZE_CONTENT=$(($DISK_SIZE_ACTUAL - $DISK_SIZE_GIT))
  if $MJS_DEBUG; then
    echo "NUM_COMMITS: ${NUM_COMMITS}"
    echo "LAST_COMMIT_DATE: ${LAST_COMMIT_DATE}"
    echo "LAST_COMMIT_UNIX: ${LAST_COMMIT_UNIX}"
    echo "LAST_COMMIT_AGE: ${LAST_COMMIT_AGE}"
    echo "NUM_FILES: ${NUM_FILES}"
    echo "DISK_SIZE_CONTENT: ${DISK_SIZE_CONTENT}"
  fi
  if [[ "$LAST_COMMIT_AGE" -gt "$OLD_AGE_DAYS" ]]; then
    HEAT=$(($HEAT + 10))
    # Add 1 heat for every 30 days past OLD_AGE_DAYS
    BASE_AGE=$(($LAST_COMMIT_AGE - $OLD_AGE_DAYS))
    HEAT=$(($HEAT + ($BASE_AGE / 30)))
    HEAT_REASON="$HEAT_REASON, no recent commits"
  fi
  if [[ "$NUM_FILES" -lt "$FEW_FILES" ]]; then
    # TODO Don't ding for few files if LAST_COMMIT_AGE is fairly recent (1yr?), or if NUM_COMMITS > 5, or DISK_SIZE_CONTENT > 16
    HEAT=$(($HEAT + (($FEW_FILES - $NUM_FILES) * 2) + 1)) #fewer files = more heat, 1 file = $FEW_FILES heat
    HEAT_REASON="$HEAT_REASON, few files"
  fi
  if [[ "$DISK_SIZE_CONTENT" -lt "$TINY_KB" ]]; then
    HEAT=$(($HEAT + ($TINY_KB - $DISK_SIZE_CONTENT) + 1)) #smaller = more heat, 1kb = $TINY_KB heat
    HEAT_REASON="$HEAT_REASON, tiny"
  fi
  cd "$REPOS_DIR"

  if [[ "$HEAT" -gt 0 ]]; then
    HEAT_REASON=${HEAT_REASON:2} # strip leading ', '
    writeRepoStats
  fi
done <${DATA_FILE}
