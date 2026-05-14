#!/usr/bin/env bash
# GitHub issue+comment monitor for the Stoa repo.
#
# Polls `gh api` for issues (opened/edited/closed) and issue comments
# created/updated after the last-seen timestamp, prints one line per new
# event to stdout, and persists the watermark to ~/.cache/stoa/gh_monitor.since
# (override with SINCE_FILE).
#
# Usage:
#   GH_REPO=hyun06000/Stoa GH_POLL_INTERVAL_S=60 \
#     bash community-tools/gh_monitor.sh &
#
# Re-runs are idempotent; on first run with no SINCE_FILE it watermarks
# to "now" (no backlog flood). Set GH_BACKFILL_HOURS=N to backfill N hours.

set -u
GH_REPO="${GH_REPO:-hyun06000/Stoa}"
INTERVAL="${GH_POLL_INTERVAL_S:-60}"
SINCE_FILE="${SINCE_FILE:-$HOME/.cache/stoa/gh_monitor.since}"
BACKFILL_HOURS="${GH_BACKFILL_HOURS:-0}"

mkdir -p "$(dirname "$SINCE_FILE")"

if [[ ! -s "$SINCE_FILE" ]]; then
  if [[ "$BACKFILL_HOURS" -gt 0 ]]; then
    SINCE=$(date -u -v-"${BACKFILL_HOURS}"H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
            || date -u -d "${BACKFILL_HOURS} hours ago" +%Y-%m-%dT%H:%M:%SZ)
  else
    SINCE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  fi
  echo "$SINCE" > "$SINCE_FILE"
fi

echo "[gh_monitor] repo=$GH_REPO interval=${INTERVAL}s since=$(cat "$SINCE_FILE")"

while true; do
  SINCE=$(cat "$SINCE_FILE")
  NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  gh api "repos/$GH_REPO/issues?since=$SINCE&state=all&per_page=100" \
    -q '.[] | select(.pull_request == null) | "\(.updated_at)\tISSUE\t#\(.number)\t\(.state)\t\(.user.login)\t\(.title)"' \
    2>/dev/null | sort -u

  gh api "repos/$GH_REPO/issues/comments?since=$SINCE&per_page=100" \
    -q '.[] | "\(.updated_at)\tCOMMENT\t#\(.issue_url | split("/") | .[-1])\t-\t\(.user.login)\t\(.body | gsub("\n"; " ") | .[:120])"' \
    2>/dev/null | sort -u

  echo "$NOW" > "$SINCE_FILE"
  sleep "$INTERVAL"
done
