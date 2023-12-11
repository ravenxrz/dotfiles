#!/bin/bash

# 
# use fswatch + rsync to sync project
# NOTE: install rsync in both local & remote side
#

# remember then last /
LOCAL_REPO_PATH=/Users/leo/Projects/pagestore/
REMOTE_NODE=wuli38
REMOTE_PATH=/data05/cache-dev/pagestore

EXCLUDE_FILE=${LOCAL_REPO_PATH}/.gitignore
EXCLUDE_PATTERN=(".git" "*/third_party/*" "*/ut_test/*")
FILE_SIZE_LIMIT=10m

SYNC_CMD="rsync -avhz --delete --force --max-size=$FILE_SIZE_LIMIT ${LOCAL_REPO_PATH}"

if [ ! -z "$EXCLUDE_FILE" ]; then
	SYNC_CMD="${SYNC_CMD}  --exclude-from=${EXCLUDE_FILE}"
fi

for pattern in "${EXCLUDE_PATTERN[@]}"; do
	SYNC_CMD="${SYNC_CMD} --exclude=$pattern"
done

# SYNC_CMD="$SYNC_CMD $REMOTE_NODE:$REMOTE_PATH --dry-run"
SYNC_CMD="$SYNC_CMD $REMOTE_NODE:$REMOTE_PATH"
echo $SYNC_CMD
eval $SYNC_CMD

while true; do
	fswatch -1 ${LOCAL_REPO_PATH} >/dev/null
	eval $SYNC_CMD
	date
	sleep 1
done
