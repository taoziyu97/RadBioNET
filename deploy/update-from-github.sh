#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/RadBioNET"
BRANCH="main"
SERVICE="radbionet.service"
LOCK_FILE="/run/lock/radbionet-update.lock"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

cd "$APP_DIR"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "RadBioNet update skipped: the server working tree has local changes." >&2
  exit 1
fi

git fetch --quiet origin "$BRANCH"

LOCAL_COMMIT="$(git rev-parse HEAD)"
REMOTE_COMMIT="$(git rev-parse "origin/$BRANCH")"

if [[ "$LOCAL_COMMIT" == "$REMOTE_COMMIT" ]]; then
  exit 0
fi

git merge --ff-only "origin/$BRANCH"
systemctl restart "$SERVICE"

echo "RadBioNet updated from $LOCAL_COMMIT to $REMOTE_COMMIT."
