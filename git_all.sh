#!/bin/bash


# Reads $DATA_FILE, clones all repos not already cloned, finds and pulls
# the most-recent branch.



MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #location of this script
DATA_FILE="${MY_DIR}/ssh_urls"
REPOS_DIR="$MY_DIR/repos"
NUM_REPOS=$(wc -l "$DATA_FILE" | awk '{print $1}')

CURRENT_NUM=1
cd "$REPOS_DIR"
while read REPO_URL; do
  echo "${CURRENT_NUM}/${NUM_REPOS}"
  REPO_NAME=$(basename "$REPO_URL" .git)
  REPO_DIR="$REPOS_DIR/$REPO_NAME"
  echo "$REPO_DIR"

  if [[ ! -d "$REPO_DIR" ]]; then
    cd "$REPOS_DIR"
    git clone "$REPO_URL"
  fi
  cd "$REPO_DIR"
  #find newest branch and pull it
  git fetch
  LATEST_BRANCH_NAME=$(git branch -a --sort=-committerdate | head -1 | awk '{print $1}' | sed 's/remotes\/origin\///g')
  if [ -z "$LATEST_BRANCH_NAME" ]; then
    # zero branches, empty repo
    continue
  fi
  if $MJS_DEBUG; then echo "LATEST_BRANCH_NAME: ${LATEST_BRANCH_NAME}"; fi
  git checkout $LATEST_BRANCH_NAME
  git merge --ff-only
  cd "$REPOS_DIR"

  CURRENT_NUM=$((++CURRENT_NUM))
  sleep 1 # just to avoid hitting any rate limits
done <${DATA_FILE}
