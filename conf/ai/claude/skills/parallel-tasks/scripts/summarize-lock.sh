#!/bin/bash
# Print per-task and batch elapsed for a parallel-tasks lock file.
# Usage: summarize-lock.sh <lock-file>

set -u
LOCK="${1:?usage: summarize-lock.sh <lock-file>}"
[ -f "$LOCK" ] || { echo "lock file not found: $LOCK" >&2; exit 1; }

ts_to_epoch() {
  # ISO-8601 UTC (e.g. 2026-05-24T18:29:59Z) -> seconds since epoch
  date -u -d "$1" +%s 2>/dev/null
}

fmt_elapsed() {
  local s="$1"
  printf "%dm%02ds" "$((s/60))" "$((s%60))"
}

# Discover numeric task ids (skip TASK=monitor)
tasks=$(awk '{
  for (i=1; i<=NF; i++) if ($i ~ /^TASK=[0-9]+$/) { print $i; break }
}' "$LOCK" | sort -u)

echo "── Per-task elapsed (first claim → complete) ──"
for t in $tasks; do
  num="${t#TASK=}"
  start_line=$(grep " $t EVENT=claim" "$LOCK" | head -1)
  end_line=$(grep " $t EVENT=complete" "$LOCK" | tail -1)
  if [ -z "$start_line" ] || [ -z "$end_line" ]; then
    printf "  task %s: incomplete (missing %s)\n" "$num" \
      "$([ -z "$start_line" ] && echo claim || echo complete)"
    continue
  fi
  start_ts="$(printf '%s' "$start_line" | awk '{print $1}' | cut -d= -f2)"
  end_ts="$(printf '%s' "$end_line" | awk '{print $1}' | cut -d= -f2)"
  s=$(ts_to_epoch "$start_ts")
  e=$(ts_to_epoch "$end_ts")
  [ -n "$s" ] && [ -n "$e" ] || { printf "  task %s: bad timestamps\n" "$num"; continue; }
  printf "  task %s: %s\n" "$num" "$(fmt_elapsed $((e - s)))"
done

# Batch elapsed: earliest TS line → last complete event
first_ts="$(grep -m1 "^TS=" "$LOCK" | awk '{print $1}' | cut -d= -f2)"
last_ts="$(grep "EVENT=complete" "$LOCK" | tail -1 | awk '{print $1}' | cut -d= -f2)"
if [ -n "$first_ts" ] && [ -n "$last_ts" ]; then
  s=$(ts_to_epoch "$first_ts")
  e=$(ts_to_epoch "$last_ts")
  if [ -n "$s" ] && [ -n "$e" ]; then
    echo ""
    printf "Batch elapsed: %s (first event → last complete)\n" "$(fmt_elapsed $((e - s)))"
  fi
fi

# Brief stats
total_events=$(grep -c "^TS=" "$LOCK")
claims=$(grep -c "EVENT=claim" "$LOCK")
extends=$(grep -c "EVENT=extend" "$LOCK")
advisories=$(grep -c "EVENT=advisory" "$LOCK")
echo ""
echo "── Lock stats ──"
printf "  events=%d  claims=%d  extends=%d  advisories=%d\n" \
  "$total_events" "$claims" "$extends" "$advisories"
